type t

@module("spacetime") external fromStringUnsafe: string => t = "default"
@module("spacetime") external fromFloat: float => t = "default"
@module("spacetime") external fromJsDate: Date.t => t = "default"
@scope("default") @module("spacetime") external now: unit => t = "now"
@scope("default") @module("spacetime") external today: unit => t = "today"
@scope("default") @module("spacetime") external tomorrow: unit => t = "tomorrow"
@scope("default") @module("spacetime") external yesterday: unit => t = "yesterday"

type timeUnit = [
  | #millisecond
  | #second
  | #minute
  | #quarterHour
  | #hour
  | #day
  | #week
  | #month
  | #quarter
  | #season
  | #year
  | #decade
  | #century
  | #date
]

type format = [
  | #day
  | #"day-short"
  | #"day-number"
  | #"day-ordinal"
  | #"day-pad"
  | #date
  | #"date-ordinal"
  | #"date-pad"
  | #month
  | #"iso-month"
  | #"month-short"
  | #"month-number"
  | #"month-ordinal"
  | #"month-pad"
  | #year
  | #"year-short"
  | #time
  | #"time-24"
  | #hour
  | #"hour-pad"
  | #"hour-24"
  | #"hour-24-pad"
  | #minute
  | #"minute-pad"
  | #second
  | #"second-pad"
  | #millisecond
  | #ampm
  | #quarter
  | #season
  | #era
  | #timezone
  | #offset
  | #numeric
  | #"numeric-us"
  | #"numeric-uk"
  | #"mm/dd"
  | #iso
  | #json
  | #"iso-short"
  | #"iso-utc"
  | #nice
  | #"nice-year"
  | #"nice-day"
  | #"nice-full"
]

type tz = [
  | #"Africa/Abidjan"
  | #"Africa/Accra"
  | #"Africa/Addis_Ababa"
  | #"Africa/Algiers"
  | #"Africa/Asmara"
  | #"Africa/Asmera"
  | #"Africa/Bamako"
  | #"Africa/Bangui"
  | #"Africa/Banjul"
  | #"Africa/Bissau"
  | #"Africa/Blantyre"
  | #"Africa/Brazzaville"
  | #"Africa/Bujumbura"
  | #"Africa/Cairo"
  | #"Africa/Casablanca"
  | #"Africa/Ceuta"
  | #"Africa/Conakry"
  | #"Africa/Dakar"
  | #"Africa/Dar_es_Salaam"
  | #"Africa/Djibouti"
  | #"Africa/Douala"
  | #"Africa/El_Aaiun"
  | #"Africa/Freetown"
  | #"Africa/Gaborone"
  | #"Africa/Harare"
  | #"Africa/Johannesburg"
  | #"Africa/Juba"
  | #"Africa/Kampala"
  | #"Africa/Khartoum"
  | #"Africa/Kigali"
  | #"Africa/Kinshasa"
  | #"Africa/Lagos"
  | #"Africa/Libreville"
  | #"Africa/Lome"
  | #"Africa/Luanda"
  | #"Africa/Lubumbashi"
  | #"Africa/Lusaka"
  | #"Africa/Malabo"
  | #"Africa/Maputo"
  | #"Africa/Maseru"
  | #"Africa/Mbabane"
  | #"Africa/Mogadishu"
  | #"Africa/Monrovia"
  | #"Africa/Nairobi"
  | #"Africa/Ndjamena"
  | #"Africa/Niamey"
  | #"Africa/Nouakchott"
  | #"Africa/Ouagadougou"
  | #"Africa/Porto-Novo"
  | #"Africa/Sao_Tome"
  | #"Africa/Timbuktu"
  | #"Africa/Tripoli"
  | #"Africa/Tunis"
  | #"Africa/Windhoek"
  | #"America/Adak"
  | #"America/Anchorage"
  | #"America/Anguilla"
  | #"America/Antigua"
  | #"America/Araguaina"
  | #"America/Argentina/Buenos_Aires"
  | #"America/Argentina/Catamarca"
  | #"America/Argentina/ComodRivadavia"
  | #"America/Argentina/Cordoba"
  | #"America/Argentina/Jujuy"
  | #"America/Argentina/La_Rioja"
  | #"America/Argentina/Mendoza"
  | #"America/Argentina/Rio_Gallegos"
  | #"America/Argentina/Salta"
  | #"America/Argentina/San_Juan"
  | #"America/Argentina/San_Luis"
  | #"America/Argentina/Tucuman"
  | #"America/Argentina/Ushuaia"
  | #"America/Aruba"
  | #"America/Asuncion"
  | #"America/Atikokan"
  | #"America/Atka"
  | #"America/Bahia"
  | #"America/Bahia_Banderas"
  | #"America/Barbados"
  | #"America/Belem"
  | #"America/Belize"
  | #"America/Blanc-Sablon"
  | #"America/Boa_Vista"
  | #"America/Bogota"
  | #"America/Boise"
  | #"America/Buenos_Aires"
  | #"America/Cambridge_Bay"
  | #"America/Campo_Grande"
  | #"America/Cancun"
  | #"America/Caracas"
  | #"America/Catamarca"
  | #"America/Cayenne"
  | #"America/Cayman"
  | #"America/Chicago"
  | #"America/Chihuahua"
  | #"America/Coral_Harbour"
  | #"America/Cordoba"
  | #"America/Costa_Rica"
  | #"America/Creston"
  | #"America/Cuiaba"
  | #"America/Curacao"
  | #"America/Danmarkshavn"
  | #"America/Dawson"
  | #"America/Dawson_Creek"
  | #"America/Denver"
  | #"America/Detroit"
  | #"America/Dominica"
  | #"America/Edmonton"
  | #"America/Eirunepe"
  | #"America/El_Salvador"
  | #"America/Ensenada"
  | #"America/Fort_Nelson"
  | #"America/Fort_Wayne"
  | #"America/Fortaleza"
  | #"America/Glace_Bay"
  | #"America/Godthab"
  | #"America/Goose_Bay"
  | #"America/Grand_Turk"
  | #"America/Grenada"
  | #"America/Guadeloupe"
  | #"America/Guatemala"
  | #"America/Guayaquil"
  | #"America/Guyana"
  | #"America/Halifax"
  | #"America/Havana"
  | #"America/Hermosillo"
  | #"America/Indiana/Indianapolis"
  | #"America/Indiana/Knox"
  | #"America/Indiana/Marengo"
  | #"America/Indiana/Petersburg"
  | #"America/Indiana/Tell_City"
  | #"America/Indiana/Vevay"
  | #"America/Indiana/Vincennes"
  | #"America/Indiana/Winamac"
  | #"America/Indianapolis"
  | #"America/Inuvik"
  | #"America/Iqaluit"
  | #"America/Jamaica"
  | #"America/Jujuy"
  | #"America/Juneau"
  | #"America/Kentucky/Louisville"
  | #"America/Kentucky/Monticello"
  | #"America/Knox_IN"
  | #"America/Kralendijk"
  | #"America/La_Paz"
  | #"America/Lima"
  | #"America/Los_Angeles"
  | #"America/Louisville"
  | #"America/Lower_Princes"
  | #"America/Maceio"
  | #"America/Managua"
  | #"America/Manaus"
  | #"America/Marigot"
  | #"America/Martinique"
  | #"America/Matamoros"
  | #"America/Mazatlan"
  | #"America/Mendoza"
  | #"America/Menominee"
  | #"America/Merida"
  | #"America/Metlakatla"
  | #"America/Mexico_City"
  | #"America/Miquelon"
  | #"America/Moncton"
  | #"America/Monterrey"
  | #"America/Montevideo"
  | #"America/Montreal"
  | #"America/Montserrat"
  | #"America/Nassau"
  | #"America/New_York"
  | #"America/Nipigon"
  | #"America/Nome"
  | #"America/Noronha"
  | #"America/North_Dakota/Beulah"
  | #"America/North_Dakota/Center"
  | #"America/North_Dakota/New_Salem"
  | #"America/Nuuk"
  | #"America/Ojinaga"
  | #"America/Panama"
  | #"America/Pangnirtung"
  | #"America/Paramaribo"
  | #"America/Phoenix"
  | #"America/Port-au-Prince"
  | #"America/Port_of_Spain"
  | #"America/Porto_Acre"
  | #"America/Porto_Velho"
  | #"America/Puerto_Rico"
  | #"America/Punta_Arenas"
  | #"America/Rainy_River"
  | #"America/Rankin_Inlet"
  | #"America/Recife"
  | #"America/Regina"
  | #"America/Resolute"
  | #"America/Rio_Branco"
  | #"America/Rosario"
  | #"America/Santa_Isabel"
  | #"America/Santarem"
  | #"America/Santiago"
  | #"America/Santo_Domingo"
  | #"America/Sao_Paulo"
  | #"America/Scoresbysund"
  | #"America/Shiprock"
  | #"America/Sitka"
  | #"America/St_Barthelemy"
  | #"America/St_Johns"
  | #"America/St_Kitts"
  | #"America/St_Lucia"
  | #"America/St_Thomas"
  | #"America/St_Vincent"
  | #"America/Swift_Current"
  | #"America/Tegucigalpa"
  | #"America/Thule"
  | #"America/Thunder_Bay"
  | #"America/Tijuana"
  | #"America/Toronto"
  | #"America/Tortola"
  | #"America/Vancouver"
  | #"America/Virgin"
  | #"America/Whitehorse"
  | #"America/Winnipeg"
  | #"America/Yakutat"
  | #"America/Yellowknife"
  | #"Antarctica/Casey"
  | #"Antarctica/Davis"
  | #"Antarctica/DumontDUrville"
  | #"Antarctica/Macquarie"
  | #"Antarctica/Mawson"
  | #"Antarctica/McMurdo"
  | #"Antarctica/Palmer"
  | #"Antarctica/Rothera"
  | #"Antarctica/South_Pole"
  | #"Antarctica/Syowa"
  | #"Antarctica/Troll"
  | #"Antarctica/Vostok"
  | #"Arctic/Longyearbyen"
  | #"Asia/Aden"
  | #"Asia/Almaty"
  | #"Asia/Amman"
  | #"Asia/Anadyr"
  | #"Asia/Aqtau"
  | #"Asia/Aqtobe"
  | #"Asia/Ashgabat"
  | #"Asia/Ashkhabad"
  | #"Asia/Atyrau"
  | #"Asia/Baghdad"
  | #"Asia/Bahrain"
  | #"Asia/Baku"
  | #"Asia/Bangkok"
  | #"Asia/Barnaul"
  | #"Asia/Beirut"
  | #"Asia/Bishkek"
  | #"Asia/Brunei"
  | #"Asia/Calcutta"
  | #"Asia/Chita"
  | #"Asia/Choibalsan"
  | #"Asia/Chongqing"
  | #"Asia/Chungking"
  | #"Asia/Colombo"
  | #"Asia/Dacca"
  | #"Asia/Damascus"
  | #"Asia/Dhaka"
  | #"Asia/Dili"
  | #"Asia/Dubai"
  | #"Asia/Dushanbe"
  | #"Asia/Famagusta"
  | #"Asia/Gaza"
  | #"Asia/Harbin"
  | #"Asia/Hebron"
  | #"Asia/Ho_Chi_Minh"
  | #"Asia/Hong_Kong"
  | #"Asia/Hovd"
  | #"Asia/Irkutsk"
  | #"Asia/Istanbul"
  | #"Asia/Jakarta"
  | #"Asia/Jayapura"
  | #"Asia/Jerusalem"
  | #"Asia/Kabul"
  | #"Asia/Kamchatka"
  | #"Asia/Karachi"
  | #"Asia/Kashgar"
  | #"Asia/Kathmandu"
  | #"Asia/Katmandu"
  | #"Asia/Khandyga"
  | #"Asia/Kolkata"
  | #"Asia/Krasnoyarsk"
  | #"Asia/Kuala_Lumpur"
  | #"Asia/Kuching"
  | #"Asia/Kuwait"
  | #"Asia/Macao"
  | #"Asia/Macau"
  | #"Asia/Magadan"
  | #"Asia/Makassar"
  | #"Asia/Manila"
  | #"Asia/Muscat"
  | #"Asia/Nicosia"
  | #"Asia/Novokuznetsk"
  | #"Asia/Novosibirsk"
  | #"Asia/Omsk"
  | #"Asia/Oral"
  | #"Asia/Phnom_Penh"
  | #"Asia/Pontianak"
  | #"Asia/Pyongyang"
  | #"Asia/Qatar"
  | #"Asia/Qostanay"
  | #"Asia/Qyzylorda"
  | #"Asia/Rangoon"
  | #"Asia/Riyadh"
  | #"Asia/Saigon"
  | #"Asia/Sakhalin"
  | #"Asia/Samarkand"
  | #"Asia/Seoul"
  | #"Asia/Shanghai"
  | #"Asia/Singapore"
  | #"Asia/Srednekolymsk"
  | #"Asia/Taipei"
  | #"Asia/Tashkent"
  | #"Asia/Tbilisi"
  | #"Asia/Tehran"
  | #"Asia/Tel_Aviv"
  | #"Asia/Thimbu"
  | #"Asia/Thimphu"
  | #"Asia/Tokyo"
  | #"Asia/Tomsk"
  | #"Asia/Ujung_Pandang"
  | #"Asia/Ulaanbaatar"
  | #"Asia/Ulan_Bator"
  | #"Asia/Urumqi"
  | #"Asia/Ust-Nera"
  | #"Asia/Vientiane"
  | #"Asia/Vladivostok"
  | #"Asia/Yakutsk"
  | #"Asia/Yangon"
  | #"Asia/Yekaterinburg"
  | #"Asia/Yerevan"
  | #"Atlantic/Azores"
  | #"Atlantic/Bermuda"
  | #"Atlantic/Canary"
  | #"Atlantic/Cape_Verde"
  | #"Atlantic/Faeroe"
  | #"Atlantic/Faroe"
  | #"Atlantic/Jan_Mayen"
  | #"Atlantic/Madeira"
  | #"Atlantic/Reykjavik"
  | #"Atlantic/South_Georgia"
  | #"Atlantic/St_Helena"
  | #"Atlantic/Stanley"
  | #"Australia/ACT"
  | #"Australia/Adelaide"
  | #"Australia/Brisbane"
  | #"Australia/Broken_Hill"
  | #"Australia/Canberra"
  | #"Australia/Currie"
  | #"Australia/Darwin"
  | #"Australia/Eucla"
  | #"Australia/Hobart"
  | #"Australia/LHI"
  | #"Australia/Lindeman"
  | #"Australia/Lord_Howe"
  | #"Australia/Melbourne"
  | #"Australia/North"
  | #"Australia/NSW"
  | #"Australia/Perth"
  | #"Australia/Queensland"
  | #"Australia/South"
  | #"Australia/Sydney"
  | #"Australia/Tasmania"
  | #"Australia/Victoria"
  | #"Australia/West"
  | #"Australia/Yancowinna"
  | #"Brazil/Acre"
  | #"Brazil/DeNoronha"
  | #"Brazil/East"
  | #"Brazil/West"
  | #"Canada/Atlantic"
  | #"Canada/Central"
  | #"Canada/Eastern"
  | #"Canada/Mountain"
  | #"Canada/Newfoundland"
  | #"Canada/Pacific"
  | #"Canada/Saskatchewan"
  | #"Canada/Yukon"
  | #CET
  | #"Chile/Continental"
  | #"Chile/EasterIsland"
  | #CST6CDT
  | #Cuba
  | #EET
  | #Egypt
  | #Eire
  | #EST
  | #EST5EDT
  | #"Etc/GMT"
  | #"Etc/GMT+0"
  | #"Etc/GMT+1"
  | #"Etc/GMT+10"
  | #"Etc/GMT+11"
  | #"Etc/GMT+12"
  | #"Etc/GMT+2"
  | #"Etc/GMT+3"
  | #"Etc/GMT+4"
  | #"Etc/GMT+5"
  | #"Etc/GMT+6"
  | #"Etc/GMT+7"
  | #"Etc/GMT+8"
  | #"Etc/GMT+9"
  | #"Etc/GMT-0"
  | #"Etc/GMT-1"
  | #"Etc/GMT-10"
  | #"Etc/GMT-11"
  | #"Etc/GMT-12"
  | #"Etc/GMT-13"
  | #"Etc/GMT-14"
  | #"Etc/GMT-2"
  | #"Etc/GMT-3"
  | #"Etc/GMT-4"
  | #"Etc/GMT-5"
  | #"Etc/GMT-6"
  | #"Etc/GMT-7"
  | #"Etc/GMT-8"
  | #"Etc/GMT-9"
  | #"Etc/GMT0"
  | #"Etc/Greenwich"
  | #"Etc/UCT"
  | #"Etc/Universal"
  | #"Etc/UTC"
  | #"Etc/Zulu"
  | #"Europe/Amsterdam"
  | #"Europe/Andorra"
  | #"Europe/Astrakhan"
  | #"Europe/Athens"
  | #"Europe/Belfast"
  | #"Europe/Belgrade"
  | #"Europe/Berlin"
  | #"Europe/Bratislava"
  | #"Europe/Brussels"
  | #"Europe/Bucharest"
  | #"Europe/Budapest"
  | #"Europe/Busingen"
  | #"Europe/Chisinau"
  | #"Europe/Copenhagen"
  | #"Europe/Dublin"
  | #"Europe/Gibraltar"
  | #"Europe/Guernsey"
  | #"Europe/Helsinki"
  | #"Europe/Isle_of_Man"
  | #"Europe/Istanbul"
  | #"Europe/Jersey"
  | #"Europe/Kaliningrad"
  | #"Europe/Kiev"
  | #"Europe/Kirov"
  | #"Europe/Lisbon"
  | #"Europe/Ljubljana"
  | #"Europe/London"
  | #"Europe/Luxembourg"
  | #"Europe/Madrid"
  | #"Europe/Malta"
  | #"Europe/Mariehamn"
  | #"Europe/Minsk"
  | #"Europe/Monaco"
  | #"Europe/Moscow"
  | #"Europe/Nicosia"
  | #"Europe/Oslo"
  | #"Europe/Paris"
  | #"Europe/Podgorica"
  | #"Europe/Prague"
  | #"Europe/Riga"
  | #"Europe/Rome"
  | #"Europe/Samara"
  | #"Europe/San_Marino"
  | #"Europe/Sarajevo"
  | #"Europe/Saratov"
  | #"Europe/Simferopol"
  | #"Europe/Skopje"
  | #"Europe/Sofia"
  | #"Europe/Stockholm"
  | #"Europe/Tallinn"
  | #"Europe/Tirane"
  | #"Europe/Tiraspol"
  | #"Europe/Ulyanovsk"
  | #"Europe/Uzhgorod"
  | #"Europe/Vaduz"
  | #"Europe/Vatican"
  | #"Europe/Vienna"
  | #"Europe/Vilnius"
  | #"Europe/Volgograd"
  | #"Europe/Warsaw"
  | #"Europe/Zagreb"
  | #"Europe/Zaporozhye"
  | #"Europe/Zurich"
  | #Factory
  | #GB
  | #"GB-Eire"
  | #GMT
  | #"GMT+0"
  | #"GMT-0"
  | #GMT0
  | #Greenwich
  | #Hongkong
  | #HST
  | #Iceland
  | #"Indian/Antananarivo"
  | #"Indian/Chagos"
  | #"Indian/Christmas"
  | #"Indian/Cocos"
  | #"Indian/Comoro"
  | #"Indian/Kerguelen"
  | #"Indian/Mahe"
  | #"Indian/Maldives"
  | #"Indian/Mauritius"
  | #"Indian/Mayotte"
  | #"Indian/Reunion"
  | #Iran
  | #Israel
  | #Jamaica
  | #Japan
  | #Kwajalein
  | #Libya
  | #MET
  | #"Mexico/BajaNorte"
  | #"Mexico/BajaSur"
  | #"Mexico/General"
  | #MST
  | #MST7MDT
  | #Navajo
  | #NZ
  | #"NZ-CHAT"
  | #"Pacific/Apia"
  | #"Pacific/Auckland"
  | #"Pacific/Bougainville"
  | #"Pacific/Chatham"
  | #"Pacific/Chuuk"
  | #"Pacific/Easter"
  | #"Pacific/Efate"
  | #"Pacific/Enderbury"
  | #"Pacific/Fakaofo"
  | #"Pacific/Fiji"
  | #"Pacific/Funafuti"
  | #"Pacific/Galapagos"
  | #"Pacific/Gambier"
  | #"Pacific/Guadalcanal"
  | #"Pacific/Guam"
  | #"Pacific/Honolulu"
  | #"Pacific/Johnston"
  | #"Pacific/Kanton"
  | #"Pacific/Kiritimati"
  | #"Pacific/Kosrae"
  | #"Pacific/Kwajalein"
  | #"Pacific/Majuro"
  | #"Pacific/Marquesas"
  | #"Pacific/Midway"
  | #"Pacific/Nauru"
  | #"Pacific/Niue"
  | #"Pacific/Norfolk"
  | #"Pacific/Noumea"
  | #"Pacific/Pago_Pago"
  | #"Pacific/Palau"
  | #"Pacific/Pitcairn"
  | #"Pacific/Pohnpei"
  | #"Pacific/Ponape"
  | #"Pacific/Port_Moresby"
  | #"Pacific/Rarotonga"
  | #"Pacific/Saipan"
  | #"Pacific/Samoa"
  | #"Pacific/Tahiti"
  | #"Pacific/Tarawa"
  | #"Pacific/Tongatapu"
  | #"Pacific/Truk"
  | #"Pacific/Wake"
  | #"Pacific/Wallis"
  | #"Pacific/Yap"
  | #Poland
  | #Portugal
  | #PRC
  | #PST8PDT
  | #ROC
  | #ROK
  | #Singapore
  | #Turkey
  | #UCT
  | #Universal
  | #"US/Alaska"
  | #"US/Aleutian"
  | #"US/Arizona"
  | #"US/Central"
  | #"US/East-Indiana"
  | #"US/Eastern"
  | #"US/Hawaii"
  | #"US/Indiana-Starke"
  | #"US/Michigan"
  | #"US/Mountain"
  | #"US/Pacific"
  | #"US/Samoa"
  | #UTC
  | #"W-SU"
  | #WET
  | #Zulu
]

external tzFromStringUnsafe: string => tz = "%identity"

@send external endOf: (t, timeUnit) => t = "endOf"
@send external startOf: (t, timeUnit) => t = "startOf"
@send external next: (t, timeUnit) => t = "next"
@send external last: (t, timeUnit) => t = "last"
@send external format: (t, format) => string = "format"
@send external formatString: (t, string) => string = "format"
@send external isValid: t => bool = "isValid"
@send external diff: (t, t, timeUnit) => int = "diff"
@send external toJsDate: t => Date.t = "toNativeDate"
@send external isAfter: (t, t) => bool = "isAfter"
@send external isBefore: (t, t) => bool = "isBefore"
@send external isEqual: (t, t) => bool = "isEqual"
@send external isBetween: (t, ~start: t, ~end: t, ~inclusive: bool=?) => bool = "isBetween"
@send external add: (t, float, timeUnit) => t = "add"
@send external subtract: (t, float, timeUnit) => t = "subtract"
@send external gotoCurrent: (t, @as(json`null`) _) => t = "goto"
@send external goto: (t, tz) => t = "goto"
@send external set: (t, string) => t = "set"
@send external time: (t, string) => t = "time"

type day =
  | @as("monday") Monday
  | @as("tuesday") Tuesday
  | @as("wednesday") Wednesday
  | @as("thursday") Thursday
  | @as("friday") Friday
  | @as("saturday") Saturday
  | @as("sunday") Sunday

@send external dayName: t => day = "dayName"
@send external day: (t, day, ~forward: bool=?) => t = "day"

@send external clone: t => t = "clone"

let fromString = t => {
  let date = fromStringUnsafe(t)
  if isValid(date) {
    Some(date)
  } else {
    None
  }
}

/**
 I18n
 */
module I18n = {
  type longShort = {
    long: array<string>,
    short: array<string>,
  }
  type ampm = {
    am: string,
    pm: string,
  }
  type distance = {
    past: string,
    future: string,
    present: string,
    now: string,
    almost: string,
    over: string,
    pastDistance: string => string,
    futureDistance: string => string,
  }
  type units = {
    second: string,
    seconds: string,
    minute: string,
    minutes: string,
    hour: string,
    hours: string,
    day: string,
    days: string,
    month: string,
    months: string,
    year: string,
    years: string,
  }
  type options = {
    days: longShort,
    months: longShort,
    ampm: ampm,
    distance: distance,
    units: units,
    useTitleCase: bool,
  }
  let french = {
    days: {
      long: ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"],
      short: ["lun", "mar", "mer", "jeu", "ven", "sam", "dim"],
    },
    months: {
      long: [
        "janvier",
        "février",
        "mars",
        "avril",
        "mai",
        "juin",
        "juillet",
        "août",
        "septembre",
        "octobre",
        "novembre",
        "décembre",
      ],
      short: [
        "janv",
        "févr",
        "mars",
        "avril",
        "mai",
        "juin",
        "juil",
        "août",
        "sept",
        "oct",
        "nov",
        "déc",
      ],
    },
    ampm: {
      am: "am",
      pm: "pm",
    },
    distance: {
      past: "passé",
      future: "futur",
      present: "présent",
      now: "maintenant",
      almost: "presque",
      over: "plus de",
      pastDistance: x => `il y a ${x}`,
      futureDistance: x => `dans ${x}`,
    },
    units: {
      second: "seconde",
      seconds: "secondes",
      minute: "minute",
      minutes: "minutes",
      hour: "heure",
      hours: "heures",
      day: "jour",
      days: "jours",
      month: "mois",
      months: "mois",
      year: "an",
      years: "ans",
    },
    useTitleCase: false,
  }

  @send external convert: (t, options) => unit = "i18n"
  let convert = (t, options) => {
    let converted = t->clone
    converted->convert(options)
    converted
  }
  let toFrench = t => convert(t, french)
}

module Diff = {
  type t = {
    days: int,
    hours: int,
    milliseconds: int,
    minutes: int,
    months: int,
    seconds: int,
    weeks: int,
    years: int,
    quarters: int,
  }
  type since = {
    diff: t,
    rounded: string,
    qualified: string,
    precise: string,
    abbreviated: array<string>,
    iso: string,
    direction: string,
  }
}

@send external since: (t, t) => Diff.since = "since"
@send external from: (t, t) => Diff.since = "from"
@send external fromNow: t => Diff.since = "fromNow"

@send external epoch: t => float = "epoch"

/**
  for ATD
*/
@module("spacetime")
external wrap: string => t = "default"
let unwrap = t => format(t, #iso)

module Tz = {
  @module("spacetime") external fromStringUnsafe: (string, tz) => t = "default"
  @module("spacetime") external fromFloat: (float, tz) => t = "default"
  @module("spacetime") external fromJsDate: (Date.t, tz) => t = "default"
  @scope("default") @module("spacetime") external now: tz => t = "now"
  @scope("default") @module("spacetime") external today: unit => t = "today"
  @scope("default") @module("spacetime") external tomorrow: unit => t = "tomorrow"
  @scope("default") @module("spacetime") external yesterday: unit => t = "yesterday"
}

let schema = S.string->S.transform(s => {
  parser: (value: string) => {
    let date = fromStringUnsafe(value)
    date->isValid ? date : s.fail(`Received invalid date: ${value}`)
  },
  serializer: date => date->format(#iso),
})
