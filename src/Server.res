let port = 4444

let tmdbApiKey = switch Bun.env->Bun.Env.get("TMDB_API_KEY") {
| Some(key) => key
| None => panic("TMDB_API_KEY environment variable is required")
}

type appContext = {
  session: option<Session.t>,
}

// Parse a specific cookie from the Cookie header
let getCookie = (request: Request.t, name: string) => {
  switch request->Request.headers->Headers.get("cookie") {
  | Some(cookieHeader) =>
    cookieHeader
    ->String.split("; ")
    ->Array.findMap(pair => {
      let parts = pair->String.split("=")
      if parts->Array.getUnsafe(0) == name {
        Some(parts->Array.slice(~start=1)->Array.join("="))
      } else {
        None
      }
    })
  | None => None
  }
}

let toBase64 = (str: string) =>
  Buffer.fromStringWithEncoding(str, StringEncoding.utf8)->Buffer.toStringWithEncoding(
    StringEncoding.base64,
  )
let fromBase64 = (str: string) =>
  Buffer.fromStringWithEncoding(str, StringEncoding.base64)->Buffer.toStringWithEncoding(
    StringEncoding.utf8,
  )

let sessionFromCookie = (request: Request.t) => {
  switch getCookie(request, "curio_session") {
  | Some(encoded) =>
    try {
      Some(JSON.parseOrThrow(fromBase64(encoded))->S.parseOrThrow(Session.schema))
    } catch {
    | JsExn(e) =>
      Console.error2("Error parsing session cookie", e)
      None
    }
  | None => None
  }
}

let setSessionCookie = (headers, session: Session.t) => {
  let encoded = toBase64(session->S.reverseConvertToJsonOrThrow(Session.schema)->JSON.stringify)
  headers->Headers.set(
    "Set-Cookie",
    `curio_session=${encoded}; Path=/; HttpOnly; SameSite=Lax; Max-Age=86400`,
  )
}

let clearSessionCookie = headers => {
  headers->Headers.set("Set-Cookie", "curio_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0")
}

let handler = Handlers.make(~requestToContext=async request => {
  let session = sessionFromCookie(request)
  // Verify the OAuth session still exists (survives server restarts)
  let session = switch session {
  | Some({did}) =>
    try {
      let _ = await OAuth.restoreAgent(did)
      session
    } catch {
    | JsExn(e) =>
      Console.error3("Stale OAuth session for", did, e)
      None
    }
  | None => None
  }
  {session: session}
})

// --- HTMX Handlers ---

let searchEndpoint = handler.hxGet("search", ~securityPolicy=SecurityPolicy.allow, ~handler=async ({
  request,
}) => {
  let url = URL.make(request->Request.url)
  let query = url->URL.searchParams->URLSearchParams.get("q")
  switch query {
  | Some(q) if q->String.trim != "" =>
    let results = await Tmdb.searchMulti(tmdbApiKey, q)
    if Array.length(results) > 0 {
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
        {results->Array.map(result => <MovieCard result />)->Hjsx.array}
      </div>
    } else {
      <div className="flex justify-center py-12">
        <div className="text-gray-500"> {Hjsx.string("No results found")} </div>
      </div>
    }
  | _ =>
    <div className="flex justify-center py-12">
      <div className="text-gray-500">
        {Hjsx.string("Search for movies and TV shows to get started")}
      </div>
    </div>
  }
})

// Declare all refs upfront so handlers can reference each other
let rateEndpoint = handler.hxPostRef("rate")
let wishlistEndpoint = handler.hxPostRef("wishlist")
let favoriteEndpoint = handler.hxPostRef("favorite")
handler.hxPostDefine(rateEndpoint, ~securityPolicy=SecurityPolicy.allow, ~handler=async ({
  request,
  context,
}) => {
  let formData = await Request.formData(request)
  let tmdbId = formData->FormDataHelpers.getInt("tmdbId")->Option.getOr(0)
  let mediaType = formData->FormDataHelpers.getString("mediaType")->Option.getOr("")
  let rating = formData->FormDataHelpers.getInt("rating")->Option.getOr(0)
  let title = formData->FormDataHelpers.getString("title")->Option.getOr("")
  let posterPath = formData->FormDataHelpers.getString("posterPath")->Option.getOr("")
  let review = formData->FormDataHelpers.getString("review")
  let review = switch review {
  | Some("") => None
  | other => other
  }

  let (currentRating, currentReview) = switch context.session {
  | Some(session) =>
    try {
      let agent = await OAuth.restoreAgent(session.did)
      if rating == 0 {
        await AtProto.Rating.delete(agent, session.did, AtProto.Rkey.make(~mediaType, ~tmdbId))
      } else {
        await AtProto.Rating.put(
          agent,
          session.did,
          {AtProto.RatingCollection.tmdbId, mediaType, title, posterPath, rating, review},
        )
      }
    } catch {
    | JsExn(e) => Console.error2("Error rating", e)
    }
    (rating, review)
  | None => (0, None)
  }

  // Also load current favorite/watchlist state to render the full actions block
  let (isFavorite, inWatchlist) = switch context.session {
  | Some(session) =>
    try {
      let agent = await OAuth.restoreAgent(session.did)
      let favResp = await AtProto.Favorite.list(agent, session.did)
      let watchResp = await AtProto.Watchlist.list(agent, session.did)
      (
        favResp.data.records->Array.some(f => f.value.tmdbId == tmdbId && f.value.mediaType == mediaType),
        watchResp.data.records->Array.some(w => w.value.tmdbId == tmdbId && w.value.mediaType == mediaType),
      )
    } catch {
    | _ => (false, false)
    }
  | None => (false, false)
  }

  <div className="user-actions space-y-8">
    <DetailPage.Actions
      tmdbId
      mediaType
      title
      posterPath
      currentRating
      currentReview
      isFavorite
      inWatchlist
      rateEndpoint
      wishlistEndpoint
      favoriteEndpoint
    />
    <ReviewSection.MyReview
      tmdbId mediaType title posterPath currentRating currentReview rateEndpoint
    />
  </div>
})

handler.hxPostDefine(wishlistEndpoint, ~securityPolicy=SecurityPolicy.allow, ~handler=async ({
  request,
  context,
}) => {
  let formData = await Request.formData(request)
  let tmdbId = formData->FormDataHelpers.getInt("tmdbId")->Option.getOr(0)
  let mediaType = formData->FormDataHelpers.getString("mediaType")->Option.getOr("")
  let title = formData->FormDataHelpers.getString("title")->Option.getOr("")
  let posterPath = formData->FormDataHelpers.getString("posterPath")->Option.getOr("")
  let action = formData->FormDataHelpers.getString("action")->Option.getOr("add")

  let inWatchlist = switch context.session {
  | Some(session) =>
    try {
      let agent = await OAuth.restoreAgent(session.did)
      if action == "remove" {
        await AtProto.Watchlist.delete(agent, session.did, AtProto.Rkey.make(~mediaType, ~tmdbId))
        false
      } else {
        await AtProto.Watchlist.put(
          agent,
          session.did,
          {AtProto.WatchlistCollection.tmdbId, mediaType, title, posterPath},
        )
        true
      }
    } catch {
    | JsExn(e) =>
      Console.error2("Error updating wishlist", e)
      action != "remove"
    }
  | None => false
  }

  <WatchlistButton tmdbId mediaType title posterPath inWatchlist wishlistEndpoint />
})

handler.hxPostDefine(favoriteEndpoint, ~securityPolicy=SecurityPolicy.allow, ~handler=async ({
  request,
  context,
}) => {
  let formData = await Request.formData(request)
  let tmdbId = formData->FormDataHelpers.getInt("tmdbId")->Option.getOr(0)
  let mediaType = formData->FormDataHelpers.getString("mediaType")->Option.getOr("")
  let title = formData->FormDataHelpers.getString("title")->Option.getOr("")
  let posterPath = formData->FormDataHelpers.getString("posterPath")->Option.getOr("")
  let action = formData->FormDataHelpers.getString("action")->Option.getOr("add")

  let isFavorite = switch context.session {
  | Some(session) =>
    try {
      let agent = await OAuth.restoreAgent(session.did)
      if action == "remove" {
        await AtProto.Favorite.delete(agent, session.did, AtProto.Rkey.make(~mediaType, ~tmdbId))
        false
      } else {
        await AtProto.Favorite.put(
          agent,
          session.did,
          {AtProto.FavoriteCollection.tmdbId, mediaType, title, posterPath},
        )
        true
      }
    } catch {
    | JsExn(e) =>
      Console.error2("Error updating favorite", e)
      action != "remove"
    }
  | None => false
  }

  <FavoriteButton tmdbId mediaType title posterPath isFavorite favoriteEndpoint />
})

// --- Form Action: initiate login for custom handle ---

let loginWithHandleAction = handler.formAction(
  "login-handle",
  ~securityPolicy=SecurityPolicy.allow,
  ~handler=async ({request}) => {
    let formData = await Request.formData(request)
    let handle = formData->FormDataHelpers.getString("handle")->Option.getOr("")

    try {
      let authUrl = await OAuth.authorizeUrl(handle)
      Response.makeRedirect(authUrl, ~status=302)
    } catch {
    | JsExn(e) =>
      Console.error2("Error logging in with handle", e)
      let headers = Headers.make()
      headers->Headers.set(
        "Location",
        "/login?error=" ++
        encodeURIComponent("Could not resolve handle. Check your handle and try again."),
      )
      Response.makeWithHeaders("", ~options={status: 303, headers})
    }
  },
)

let logoutAction = handler.formAction(
  "logout",
  ~securityPolicy=SecurityPolicy.allow,
  ~handler=async ({request}) => {
    let session = sessionFromCookie(request)
    switch session {
    | Some({did}) => await OAuth.signOut(did)
    | None => ()
    }
    let headers = Headers.make()
    clearSessionCookie(headers)
    headers->Headers.set("Location", "/")
    Response.makeWithHeaders("", ~options={status: 303, headers})
  },
)

// --- Main Server ---

let publicUrl = switch Bun.env->Bun.Env.get("PUBLIC_URL") {
| Some(url) => url
| None =>
  if BunUtils.isDev {
    "http://127.0.0.1:5173"
  } else {
    `http://127.0.0.1:${Int.toString(port)}`
  }
}
OAuth.initOAuthClient(publicUrl)
Console.log("OAuth client initialized")

let _server = Bun.serve({
  port,
  routes: ResXAssets.staticAssetRoutes,
  fetch: async (request, _server) => {
    let url = URL.make(request->Request.url)
    let pathname = url->URL.pathname

    // Handle OAuth callback outside res-x handler (it returns a redirect, not HTML)
    switch pathname {
    | "/oauth/callback" =>
      // Handle OAuth callback
      try {
        let session = await OAuth.handleCallback(url->URL.searchParams)
        let headers = Headers.make()
        setSessionCookie(headers, session)
        headers->Headers.set("Location", "/")
        Response.makeWithHeaders("", ~options={status: 303, headers})
      } catch {
      | JsExn(e) =>
        Console.error2("OAuth callback error", e)
        Response.makeRedirect(
          `/login?error=${encodeURIComponent("Login failed. Please try again.")}`,
          ~status=303,
        )
      }

    | _ =>
      await handler.handleRequest({
        request,
        // Clear stale session cookie when OAuth session no longer exists
        onBeforeSendResponse: async ({request, response, context}) => {
          let hasCookie = sessionFromCookie(request)->Option.isSome
          let hasSession = context.session->Option.isSome
          if hasCookie && !hasSession {
            response
            ->Response.headers
            ->Headers.set("Set-Cookie", "curio_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0")
          }
          response
        },
        render: async ({path, url, requestController, context}) => {
          requestController.setFullTitle("Curio")
          requestController.appendToHead(
            <>
              <link rel="stylesheet" href={ResXAssets.assets.index_css} />
              <script
                src="https://unpkg.com/htmx.org@2.0.4"
                integrity="sha384-HGfztofotfshcF7+8n44JQL2oJmowVChPTg48S+jvZoztPfvwD79OC/LTtG6dMp+"
                crossOrigin="anonymous"
              />
            </>,
          )
          requestController.appendBeforeBodyEnd(<script src={ResXAssets.assets.resXClient_js} />)

          <html lang="en">
            <head>
              <meta charSet="UTF-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            </head>
            <body className="min-h-screen bg-gray-950 text-gray-100">
              <Navbar session={context.session} logoutAction />
              <main>
                {switch path {
                | list{} => <SearchPage searchEndpoint />
                | list{"login"} =>
                  let error = url->URL.searchParams->URLSearchParams.get("error")
                  <LoginPage loginWithHandleAction error />
                | list{"movie", id} =>
                  <DetailPage
                    mediaType="movie"
                    id
                    apiKey=tmdbApiKey
                    session={context.session}
                    rateEndpoint
                    wishlistEndpoint
                    favoriteEndpoint
                  />
                | list{"tv", id} =>
                  <DetailPage
                    mediaType="tv"
                    id
                    apiKey=tmdbApiKey
                    session={context.session}
                    rateEndpoint
                    wishlistEndpoint
                    favoriteEndpoint
                  />
                | list{userHandle, "ratings"} if userHandle->String.startsWith("@") =>
                  <RatingsPage session={context.session} handle={userHandle->Handle.fromString} />
                | list{userHandle, "wishlist"} if userHandle->String.startsWith("@") =>
                  <WatchlistPage session={context.session} handle={userHandle->Handle.fromString} />
                | _ =>
                  <div className="flex justify-center py-20">
                    <h1 className="text-2xl text-gray-500"> {Hjsx.string("Page not found")} </h1>
                  </div>
                }}
              </main>
            </body>
          </html>
        },
      })
    }
  },
})

// Start dev server for hot reload in development
if BunUtils.isDev {
  BunUtils.runDevServer(~port)
}

Console.log(`Curio server running on http://localhost:${Int.toString(port)}`)
