open Xote

module NotFoundPage = {
  type props = {}

  let make = (_props: props) => {
    <div class="not-found">
      <h1> {Component.text("404")} </h1>
      <p> {Component.text("The page you're looking for doesn't exist.")} </p>
      {Router.link(
        ~to="/",
        ~attrs=[Component.attr("class", "btn btn-primary")],
        ~children=[Component.text("Go Home")],
        (),
      )}
    </div>
  }
}

@jsx.component
let make = () => {
  <div>
    <Navbar />
    <main>
      {Router.routes([
        {
          pattern: "/",
          render: _params => <SearchPage />,
        },
        {
          pattern: "/movie/:id",
          render: params => {
            let id = params->Dict.get("id")->Option.getOr("0")
            <DetailPage mediaType="movie" id />
          },
        },
        {
          pattern: "/tv/:id",
          render: params => {
            let id = params->Dict.get("id")->Option.getOr("0")
            <DetailPage mediaType="tv" id />
          },
        },
        {
          pattern: "/@:handle/wishlist",
          render: params => {
            let handle = params->Dict.get("handle")->Option.getOr("")
            <WishlistPage handle />
          },
        },
        {
          pattern: "/@:handle/ratings",
          render: params => {
            let handle = params->Dict.get("handle")->Option.getOr("")
            <RatingsPage handle />
          },
        },
        {
          pattern: "*",
          render: _ => <NotFoundPage />,
        },
      ])}
    </main>
  </div>
}
