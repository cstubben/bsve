`bsve` is an `R` package for developers to access the
[BSVE](http://developer.bsvecosystem.net) [API](http://developer.bsvecosystem.net/wp/tutorials/bsve-data-api)


###Installation

The package requires a recent version of `openssl` to create the hash
key and `httr` to get data.

```
library(devtools)
install_github("cstubben/bsve")
```

###Connecting

You will need to get the API and secret key from the developer site
under My Account -> Manage API Credentials and replace them below.

```
api_key    <- "API key"
secret_key <- "SECRET key"
email      <- "and your@email"
```

The `bsve_sha1` function creates the authentication header using the
two keys and a valid email.

```

token <- bsve_sha1(api_key, secret_key, email)
token
[1] "apikey=AKcfef08f1-c852-43b9-bce7-8923880e3b68;timestamp=1457989545992;nonce=535514;signature=f6b90ed483b37..."
```


###4.4 Find All DataSources

If you are not familiar with `httr`, be sure to check the [quickstart
guide](https://github.com/hadley/httr/blob/master/vignettes/quickstart.Rmd).
This code will list all data sources


```
url <- "http://search.bsvecosystem.net/api/data/list"
r <- GET(url, add_headers("harbinger-authentication" = token))
r
Response [http://search.bsvecosystem.net/api/data/list]
  Date: 2016-03-16 21:44
  Status: 200
  Content-Type: application/json;charset=UTF-8
  Size: 72.1 kB
http_status(r)
$category
[1] "success"
```

Parse the results into a nested list (`content` uses `fromJSON` in
`jsonlite` by default).
```
x <- content(r)

sapply(x, length)
 status message  result 
      1       1      21 
names(x$result[[1]])
[1] "name"        "description" "fileTypes"   "label"       "shortLabel"  "fields"     
[7] "dataSources" "type"        "attributes" 
```

Both `fields` and `dataSources` are arrays with 0 to many elements, so just grab the first 5 keys and count the number of fields
and dataSources below.  This requires `rbind_all` in the `dplyr` package.

```
b1 <-rbind_all(lapply( x$result, "[", 1:5 ) )
b1$fields <- sapply( x$result, function(y) length( y$fields) )
b1$dataSources <- sapply( x$result, function(y) length( y$dataSources) )

b1[, c(1:2,6:7)] %>% print(n=30)
                   name                             description fields dataSources
                  (chr)                                   (chr)  (int)       (int)
1                AFCENT                            Clinic Visit     39           3
2      AGG_CASE_LISTING                 Aggregated Case Listing      0           0
3        BLANK_TEMPLATE                          Blank Template      0           0
4        Demo Data Type Testing addition of data to repository.      2           0
5  DORAAirportProximity                Distance from an airport      3           8
6                 EIDSS                         EIDSS Flat File     22           0
7                 EMAIL                              Email Feed     18           1
8          EventTracker                           Event Tracker      0           0
9       HydraSourceType          Test dataSource type for hydra      4           2
10            HydraType          Test dataSource type for hydra      4           1
11       IND_CASE_LINES                   Individual_Case_Lines      0           0
12            Leidos Wx          Weather for use by Leidos apps      2           0
13             LeidosWx          Weather for use by Leidos apps      2           0
14                  NDD                           NDD Flat File     20           0
15                  PON                           PON Flat File     31           1
16                  RSS                                RSS Feed     18          65
17         RSS_FLATFILE                           RSS Flat File      0           0
18                   SD                     Syndromic Flat File     15           0
19                 SODA                          SODA Flat File      0          15
20              TWITTER                       Twitter Flat File      0           1
21            WEBSEARCH                              Web Search      0           0
```

Also use `rbind_all` to get the 18 RSS fields in list element 16.

```
rbind_all(x$result[[16]]$fields)

               name    type format      description position
              (chr)   (chr)  (chr)            (chr)    (int)
1            source  String                  source        0
2                id  String                      id        0
3       description  String             description        0
4             title  String                   title        0
5           content  String                 content        0
6           pubDate    Date                 pubDate        0
7              link  String                    link        0
8          filename  String                filename        0
9             cases  String                   cases        0
10           deaths  String                  deaths        0
11 hospitalizations  String        hospitalizations        0
12         latitude   Float                latitude        0
13        longitude   Float               longitude        0
14        simulated Boolean               simulated        0
15             what  String                    what        0
16             when  String                    when        0
17            where  String                   where        0
18              who  String                     who        0
```


You can list the 65 RSS dataSources below.  Contacts and other fields
have 0 to many values, so just get the first three.

```
names(x$result[[16]]$dataSources[[1]])
[1] "name"         "type"         "category"     "description"  "status"       "contacts"    
[7] "schema"       "tags"         "capabilities"


rbind_all( lapply(x$result[[16]]$dataSources, "[",  1:3) )
                                             name  type        category
                                           (chr) (chr)           (chr)
1                             Agriculture Canada   RSS   Expert Domain
2          Agrifeeds Animal Diseases and Control   RSS   Expert Domain
3  AgriFeeds News on Phytosanitary Measures IPPC   RSS   Expert Domain
4  AgriFeeds News on Plant Pathology and Disease   RSS   Expert Domain
5                         Agrifeeds Pest Control   RSS   Expert Domain
6                            AP Top Science News   RSS Non-Domain News
7                                Avian Flu Diary   RSS     Domain News
8                            Buenos Aires Herald   RSS Non-Domain News
9                           CDC MMWR Quick Stats   RSS   Expert Domain
10                              CDC MMWR Reports   RSS   Expert Domain
..                                           ...   ...             ...
```

###4.6 Querying the Datasource API

Use `api/data/query/{data}` to query RSS or other datasets.  

```
url1 <- "http://search.bsvecosystem.net/api/data/query/RSS"

r1 <- GET(url1,  add_headers("harbinger-authentication" = token),
  query = list(`$source` = "CDC MMWR Reports",  `$filter`="pubDate ge 2016-02-01") )

x1 <- content(r1)
x1
$status
[1] 0

$message
[1] "In Progress"

$query
$query$type
[1] "RSS"

$query$sources
[1] "CDC MMWR Reports"

$query$filter
[1] "pubDate ge 2016-02-01"


$requestId
[1] "135171b2-308b-4ae3-955f-46c6b651611d"
```


###4.7 Getting Datasource Results

You need the `requestId` above to download the results.

```
url2 <- "http://search.bsvecosystem.net/api/data/result/"
r2 <-  GET( paste0(url2, x1$requestId), add_headers("harbinger-authentication" = token))
x2 <- content(r2)

sapply(x2, length)
   status   message    result     count     query requestId 
   1         1         7         1         3         1
   
names(x2$result[[1]])
 [1] "id"                  "source"              "dataSourceName"      "simulated"          
 [5] "textRelevance"       "pubdate"             "title"               "link"               
 [9] "description"         "content"             "latitude"            "longitude"          
[13] "noofcases"           "noofhospitalization" "noofdeaths"          "who"                
[17] "what"                "when"                "where"               "filename"  

sapply(x2$result,  "[[", "title")
[1] "EARLY RELEASE: Vital Signs: Preventing Antibiotic-Resistant Infections in Hospitals Ã¢Â\u0080Â\u0094 United States, 2014"                                         
[2] "SUPPLEMENTS: Development of the Community Health Improvement Navigator Database of Interventions"                                                                 
[3] "Transmission of Zika Virus Through Sexual Contact with Travelers to Areas of Ongoing Transmission Ã¢Â\u0080Â\u0094 Continental United States, 2016"               
[4] "EARLY RELEASE: Transmission of Zika Virus Through Sexual Contact with Travelers to Areas of Ongoing Transmission Ã¢Â\u0080Â\u0094 Continental United States, 2016"
...
```


Note, I'm not sure how to fix the encoding in title names above.  You
can check using `stringi`, but adding an encoding option does not help.

```
stringi::stri_enc_detect(content(r2, "raw"))
[[1]]
[[1]]$Encoding
[1] "UTF-8"        "windows-1252" "windows-1250" "UTF-16BE"     "UTF-16LE"     "windows-1254"

[[1]]$Language
[1] ""   "en" "ro" ""   ""   "tr"

[[1]]$Confidence
[1] 1.00 0.54 0.20 0.10 0.10 0.08

x2 <- content(r2, encoding="UTF-8")
sapply(x2$result,  "[[", "title") 
```

The pubdates can be converted using as.POSIXct.

```
sapply(x2$result,  "[[", "pubdate")
[1] "1457112660000" "1456509505000" "1457112600000" "1456511400000" "1456507345000"
[6] "1456500085000" "1456511400000"

as.POSIXct( round(as.numeric(z)/1000), origin = "1970-01-01")
[1] "2016-03-04 10:31:00 MST" "2016-02-25 10:58:25 MST" "2016-03-04 10:30:00 MST" ...
```

These last two steps are combined in the `get_bsve` function.  Without
a filter, all 978 titles are returned.  The function includes API
options for `top`, `skip`  and `orderby`  (although orderby still does
not work)

```
x1 <- get_bsve(token, "RSS", source ="CDC MMWR Reports")
x2 <- get_bsve(token, "RSS", source ="CDC MMWR Reports", filter="pubdate ge 2016-02-01")
x3 <- get_bsve(token, "RSS", source ="CDC MMWR Reports", filter="pubdate ge 2016-02-01", orderby="pubdate DESC", top=5)
order(sapply(x3$result,  "[[", "pubdate"))
[1] 5 2 4 3 1

```



