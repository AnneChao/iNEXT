
#
#
###############################################
#' ggplot2 extension for an iNEXT object
#' 
#' \code{ggiNEXT}: the \code{\link[ggplot2]{ggplot}} extension for \code{\link{iNEXT}} Object to plot sample-size- and coverage-based rarefaction/extrapolation curves along with a bridging sample completeness curve
#' @param x an \code{iNEXT} object computed by \code{\link{iNEXT}}.
#' @param type three types of plots: sample-size-based rarefaction/extrapolation curve (\code{type = 1}); 
#' sample completeness curve (\code{type = 2}); coverage-based rarefaction/extrapolation curve (\code{type = 3}).                 
#' @param se a logical variable to display confidence interval around the estimated sampling curve.
#' @param facet.var create a separate plot for each value of a specified variable: 
#'  no separation \cr (\code{facet.var="none"}); 
#'  a separate plot for each diversity order (\code{facet.var="order"}); 
#'  a separate plot for each site (\code{facet.var="site"}); 
#'  a separate plot for each combination of order x site (\code{facet.var="both"}).              
#' @param color.var create curves in different colors for values of a specified variable:
#'  all curves are in the same color (\code{color.var="none"}); 
#'  use different colors for diversity orders (\code{color.var="order"}); 
#'  use different colors for sites (\code{color.var="site"}); 
#'  use different colors for combinations of order x site (\code{color.var="both"}).  
#' @param grey a logical variable to display grey and white ggplot2 theme. 
#' @param ... other arguments passed on to methods. Not currently used.
#' @return a ggplot2 object
#' @examples
#' data(spider)
#' # single-assemblage abundance data
#' out1 <- iNEXT(spider$Girdled, q=0, datatype="abundance")
#' ggiNEXT(x=out1, type=1)
#' ggiNEXT(x=out1, type=2)
#' ggiNEXT(x=out1, type=3)
#' 
#'\dontrun{
#' # single-assemblage incidence data with three orders q
#' data(ant)
#' size <- round(seq(10, 500, length.out=20))
#' y <- iNEXT(ant$h500m, q=c(0,1,2), datatype="incidence_freq", size=size, se=FALSE)
#' ggiNEXT(y, se=FALSE, color.var="order")
#' 
#' # multiple-assemblage abundance data with three orders q
#' z <- iNEXT(spider, q=c(0,1,2), datatype="abundance")
#' ggiNEXT(z, facet.var="site", color.var="order")
#' ggiNEXT(z, facet.var="both", color.var="both")
#'}
#' @export
#' 
ggiNEXT <- function(x, type=1, se=TRUE, facet.var="none", color.var="site", grey=FALSE){  
  UseMethod("ggiNEXT", x)
}

#' @export
#' @rdname ggiNEXT
ggiNEXT.iNEXT <- function(x, type=1, se=TRUE, facet.var="none", color.var="site", grey=FALSE){
  cbPalette <- rev(c("#999999", "#E69F00", "#56B4E9", "#009E73", "#330066", "#CC79A7",  "#0072B2", "#D55E00"))
  TYPE <-  c(1, 2, 3)
  SPLIT <- c("none", "order", "site", "both")
  if(is.na(pmatch(type, TYPE)) | pmatch(type, TYPE) == -1)
    stop("invalid plot type")
  if(is.na(pmatch(facet.var, SPLIT)) | pmatch(facet.var, SPLIT) == -1)
    stop("invalid facet variable")
  if(is.na(pmatch(color.var, SPLIT)) | pmatch(color.var, SPLIT) == -1)
    stop("invalid color variable")
  
  type <- pmatch(type, 1:3)
  facet.var <- match.arg(facet.var, SPLIT)
  color.var <- match.arg(color.var, SPLIT)
  if(facet.var=="order") color.var <- "site"
  if(facet.var=="site") color.var <- "order"
  
  options(warn = -1)
  z <- fortify(x, type=type)
  options(warn = 0)
  if(ncol(z) ==7) {se <- FALSE}
  datatype <- unique(z$datatype)
  if(color.var=="none"){
    if(levels(factor(z$order))>1 & "site"%in%names(z)){
      warning("invalid color.var setting, the iNEXT object consists multiple sites and orders, change setting as both")
      color.var <- "both"
      z$col <- z$shape <- paste(z$site, z$order, sep="-")
      
    }else if("site"%in%names(z)){
      warning("invalid color.var setting, the iNEXT object consists multiple orders, change setting as order")
      color.var <- "site"
      z$col <- z$shape <- z$site
    }else if(levels(factor(z$order))>1){
      warning("invalid color.var setting, the iNEXT object consists multiple sites, change setting as site")
      color.var <- "order"
      z$col <- z$shape <- factor(z$order)
    }else{
      z$col <- z$shape <- rep(1, nrow(z))
    }
  }else if(color.var=="order"){     
    z$col <- z$shape <- factor(z$order)
  }else if(color.var=="site"){
    if(!"site"%in%names(z)){
      warning("invalid color.var setting, the iNEXT object do not consist multiple sites, change setting as order")
      z$col <- z$shape <- factor(z$order)
    }
    z$col <- z$shape <- z$site
  }else if(color.var=="both"){
    if(!"site"%in%names(z)){
      warning("invalid color.var setting, the iNEXT object do not consist multiple sites, change setting as order")
      z$col <- z$shape <- factor(z$order)
    }
    z$col <- z$shape <- paste(z$site, z$order, sep="-")
  }
  zz=z
  z$method[z$method=="observed"]="interpolated"
  z$lty <- z$lty <- factor(z$method, levels=unique(c("interpolated", "extrapolated"),
                                                   c("interpolation", "interpolation", "extrapolation")))
  z$col <- factor(z$col)
  data.sub <- zz[which(zz$method=="observed"),]
  
  g <- ggplot(z, aes_string(x="x", y="y", colour="col")) + 
    geom_point(aes_string(shape="shape"), size=5, data=data.sub)+
    scale_colour_manual(values=cbPalette)
  
  
  g <- g + geom_line(aes_string(linetype="lty"), lwd=1.5) +
    guides(linetype=guide_legend(title="Method"),
           colour=guide_legend(title="Guides"), 
           fill=guide_legend(title="Guides"), 
           shape=guide_legend(title="Guides")) +
    theme(legend.position = "bottom", 
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.key.width = unit(1.2,"cm")) 
  
  if(type==2L) {
    g <- g + labs(x="Number of sampling units", y="Sample coverage")
    if(datatype=="abundance") g <- g + labs(x="Number of individuals", y="Sample coverage")
  }
  else if(type==3L) {
    g <- g + labs(x="Sample coverage", y="Species diversity")
  }
  else {
    g <- g + labs(x="Number of sampling units", y="Species diversity")
    if(datatype=="abundance") g <- g + labs(x="Number of individuals", y="Species diversity")
  }
  
  if(se)
    g <- g + geom_ribbon(aes_string(ymin="y.lwr", ymax="y.upr", fill="factor(col)", colour="NULL"), alpha=0.2)+
    scale_fill_manual(values=cbPalette)
  
  
  if(facet.var=="order"){
    if(length(levels(factor(z$order))) == 1 & type!=2){
      warning("invalid facet.var setting, the iNEXT object do not consist multiple orders.")      
    }else{
      odr_grp <- as_labeller(c(`0` = "q = 0", `1` = "q = 1",`2` = "q = 2")) 
      g <- g + facet_wrap(~order, nrow=1, labeller = odr_grp)
      if(color.var=="both"){
        g <- g + guides(colour=guide_legend(title="Guides", ncol=length(levels(factor(z$order))), byrow=TRUE),
                        fill=guide_legend(title="Guides"))
      }
      if(type==2){
        g <- g + theme(strip.background = element_blank(),strip.text.x = element_blank())
          
      }
    }
  }
  
  if(facet.var=="site"){
    if(!"site"%in%names(z)) {
      warning("invalid facet.var setting, the iNEXT object do not consist multiple sites.")
    }else{
      g <- g + facet_wrap(~site, nrow=1)
      if(color.var=="both"){
        g <- g + guides(colour=guide_legend(title="Guides", nrow=length(levels(factor(z$order)))),
                        fill=guide_legend(title="Guides"))
      }
    }
  }
  
  if(facet.var=="both"){
    if(length(levels(factor(z$order))) == 1 | !"site"%in%names(z)){
      warning("invalid facet.var setting, the iNEXT object do not consist multiple sites or orders.")
    }else{
      odr_grp <- as_labeller(c(`0` = "q = 0", `1` = "q = 1",`2` = "q = 2")) 
      g <- g + facet_wrap(site~order,labeller = labeller(order = odr_grp)) 
      if(color.var=="both"){
        g <- g +  guides(colour=guide_legend(title="Guides", nrow=length(levels(factor(z$site))), byrow=TRUE),
                         fill=guide_legend(title="Guides"))
      }
    }
  }
  
  if(grey){
    g <- g + theme_bw(base_size = 18) +
      scale_fill_grey(start = 0, end = .4) +
      scale_colour_grey(start = .2, end = .2) +
      guides(linetype=guide_legend(title="Method"), 
             colour=guide_legend(title="Guides"), 
             fill=guide_legend(title="Guides"), 
             shape=guide_legend(title="Guides")) +
      theme(legend.position="bottom",
            legend.title=element_blank())
  }
  g <- g + theme(legend.box = "vertical")
  return(g)
  
}

#' @export
#' @rdname ggiNEXT
ggiNEXT.default <- function(x, ...){
  stop(
    "iNEXT doesn't know how to deal with data of class ",
    paste(class(x), collapse = "/"),
    call. = FALSE
  )
}

#' Fortify method for classes from the iNEXT package.
#'
#' @name fortify.iNEXT
#' @param model \code{iNEXT} to convert into a dataframe.
#' @param data not used by this method
#' @param type three types of plots: sample-size-based rarefaction/extrapolation curve (\code{type = 1}); 
#' sample completeness curve (\code{type = 2}); coverage-based rarefaction/extrapolation curve (\code{type = 3}).                 
#' @param ... not used by this method
#' @export
#' @examples
#' data(spider)
#' # single-assemblage abundance data
#' out1 <- iNEXT(spider$Girdled, q=0, datatype="abundance")
#' ggplot2::fortify(out1, type=1)

fortify.iNEXT <- function(model, data = model$iNextEst, type = 1, ...) {
  datatype <- ifelse(names(model$DataInfo)[2]=="n","abundance","incidence")
  z <- data
  if(class(z) == "list"){
    z <- data.frame(do.call("rbind", z), site=rep(names(z), sapply(z, nrow)))
    rownames(z) <- NULL
  }else{
    z$site <- ""
  }
  
  if(ncol(z)==6) {
    warning("invalid se setting, the iNEXT object do not consist confidence interval")
    se <- FALSE
  }else if(ncol(z)>6) {
    se <- TRUE
  }
  
  if(type==1L) {
    z$x <- z[,1]
    z$y <- z$qD
    if(se){
      z$y.lwr <- z[,5]
      z$y.upr <- z[,6]
    }
  }else if(type==2L){
    if(length(unique(z$order))>1){
      z <- subset(z, order==unique(z$order)[1])
    }
    z$x <- z[,1]
    z$y <- z$SC
    if(se){
      z$y.lwr <- z[,8]
      z$y.upr <- z[,9]
    }
  }else if(type==3L){
    z$x <- z$SC
    z$y <- z$qD
    if(se){
      z$y.lwr <- z[,5]
      z$y.upr <- z[,6]
    }
  }
  z$datatype <- datatype
  z$plottype <- type
  if(se){
    data <- z[,c("datatype","plottype","site","method","order","x","y","y.lwr","y.upr")]
  }else{
    data <- z[,c("datatype","plottype","site","method","order","x","y")]
  }
  data
}

