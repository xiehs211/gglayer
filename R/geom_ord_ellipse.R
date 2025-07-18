##' add confidence ellipse to ordinary plot produced by ggord
##'
##' 
##' @title add confidence ellipse to ordinary plot
##' @param mapping aes mapping 
##' @param ellipse_pro confidence value for the ellipse
##' @param fill color to fill the ellipse, NA by default
##' @param ... additional parameters
##' @return ggplot layer
##' @importFrom ggplot2 aes_
##' @importFrom ggplot2 layer
##' @importFrom utils modifyList
##' @export
##' @author Guangchuang Yu
##' @examples
##' \dontrun{
##' library(MASS)
##' ord <- lda(Species ~ ., iris, prior = rep(1, 3)/3)
##' ## devtools::install_github('fawda123/ggord')
##' library(ggord)
##' p <- ggord(ord, iris$Species)
##' p + geom_ord_ellipse(ellipse_pro = .96, color='firebrick', size=1, lty=3) +
##' geom_ord_ellipse(ellipse_pro = .99, lty=2)
##' }
## @references \url{https://lchblogs.netlify.com/post/2017-12-22-r-addconfellipselda/}
geom_ord_ellipse <- function(mapping = NULL, ellipse_pro = 0.97, fill = NA, ...) {
    default_aes <- aes_(color = ~Groups, group = ~Groups)
    if (is.null(mapping)) {
        mapping <- default_aes
    } else {
        mapping <- modifyList(default_aes, mapping)
    }
    
    layer(
        geom = "polygon",
        stat = StatOrdEllipse,
        mapping = mapping,
        position = 'identity',
        data = NULL,
        params = list(
            ellipse_pro = ellipse_pro,
            fill = fill,
            ...
        )
    )
}

##' @importFrom ggplot2 ggproto
##' @importFrom ggplot2 Stat
##' @importFrom plyr ddply
##' @importFrom grDevices chull
StatOrdEllipse <- ggproto("StatOrdEllipse", Stat,
                          compute_group = function(self, data, scales, params, ellipse_pro) {
                              # Fix: Replace hardcoded column indexing with precise column name targeting
                              # This prevents errors when data contains additional columns like Groups
                              if (!all(c("x", "y") %in% names(data))) {
                                  stop("Required aesthetics: x and y")
                              }
                              # Rename coordinate columns while preserving other columns
                              colnames(data)[colnames(data) == "x"] <- "one"
                              colnames(data)[colnames(data) == "y"] <- "two"
                              
                              theta <- c(seq(-pi, pi, length = 50), seq(pi, -pi, length = 50))
                              circle <- cbind(cos(theta), sin(theta))
                              ell <- ddply(data, .(group), function(x) {
                                  if(nrow(x) <= 2) {
                                      return(NULL)
                                  }
                                  sigma <- var(cbind(x$one, x$two))
                                  mu <- c(mean(x$one), mean(x$two))
                                  ed <- sqrt(qchisq(ellipse_pro, df = 2))
                                  data.frame(sweep(circle %*% chol(sigma) * ed, 2, mu, FUN = '+'))
                              })
                              names(ell)[2:3] <- c('one', 'two')
                              ell <- ddply(ell, .(group), function(x) x[chull(x$one, x$two), ])
                              names(ell) <- c('Groups', 'x', 'y')
                              return(ell)
                          },
                          required_aes = c("x", "y", "group")
                          )


globalVariables('.')

## . function was from plyr package
## . <- function (..., .env = parent.frame()) {
##    structure(as.list(match.call()[-1]), env = .env, class = "quoted")
##}