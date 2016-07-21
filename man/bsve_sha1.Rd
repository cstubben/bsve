\name{bsve_sha1}
\alias{bsve_sha1}
\title{ Create the BSVE authenication header  }
\description{ Creates the BSVE authenication header using sha1 from the openssl package }
\usage{
bsve_sha1(api_key, secret_key, email)
}

\arguments{
  \item{api_key}{ API key }
  \item{secret_key}{ Secret key }
  \item{email}{ email }
}
\details{ The API and Secret key are available from the developer My Account page by following link to Manage My Credentials }
\value{  a vector }
%\references{ }
\author{ Chris Stubben }
% \note{}
% \seealso{ }
\examples{
 # replace these values
api_key <- "AKcfef08f1-c852-..."
secret_key <-  "mySECRETkey" 
email <-  "my@email"
token <- bsve_sha1(api_key, secret_key, email)
token

}

\keyword{ methods }
