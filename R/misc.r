###########################################################################
#
#   nonadaptive 1D -- 3D smoothing on a grid (kernel supported on (-1,1))
#
###########################################################################
ckernsm2<-function (y, h = 1, lkern="Triangle"){
   grid <- function(d,h) {
        d0 <- d%/%2 + 1
        gd <- seq(0, 1, length = d0)
        if (2 * d0 == d + 1)
            gd <- c(gd, -gd[d0:2],)
        else gd <- c(gd, -gd[(d0 - 1):2])
        gd/2/h*d
   }
   dimy <- dim(y)
   ih <- trunc(h)
   d1<-nextn(dimy[1]+2*ih)
   d2<-nextn(dimy[2]+2*ih)
   yy<-matrix(0,d1,d2)
   indx <- ih+(1:dimy[1])
   indy <- ih+(1:dimy[2])
   yy[indx,indy]<-y
   kern1 <- switch(lkern,Uniform=as.numeric(abs(grid(d1,h))<1),
                            Triangle=pmax(1-grid(d1,h)^2,0),
                            Quadratic=pmax(1-grid(d1,h)^2,0)^2,
                            Cubic=pmax(1-grid(d1,h)^2,0)^3)
   kern2 <- switch(lkern,Uniform=as.numeric(abs(grid(d2,h))<1),
                            Triangle=pmax(1-grid(d2,h)^2,0),
                            Quadratic=pmax(1-grid(d2,h)^2,0)^2,
                            Cubic=pmax(1-grid(d2,h)^2,0)^3)
   kern <- outer(kern1,kern2,"*")
   sumkern <- sum(kern)
       yhat<-Re(fft(fft(yy) * fft(kern),inv=TRUE))/d1/d2/sumkern
      list(theta=yhat[indx,indy],bi=sumkern)
}
###########################################################################
#
#   nonadaptive 1D -- 3D smoothing on a grid (kernel supported on (-1,1))
#
###########################################################################
ckernsm2p<-function (y, theta, h = 1, lkern="Triangle"){
   grid <- function(d,h) {
        d0 <- d%/%2 + 1
        gd <- seq(0, 1, length = d0)
        if (2 * d0 == d + 1)
            gd <- c(gd, -gd[d0:2],)
        else gd <- c(gd, -gd[(d0 - 1):2])
        gd/2/h*d
   }
   dimy <- dim(y)
   ih <- trunc(h)
   d1<-nextn(dimy[1]+2*ih,c(2,3,5))
   d2<-nextn(dimy[2]+2*ih,c(2,3,5))
   yy <- ytheta <- matrix(0,d1,d2)
   indx <- ih+(1:dimy[1])
   indy <- ih+(1:dimy[2])
   yy[indx,indy]<-y
   ytheta[indx,indy]<-theta
   kern1 <- switch(lkern,Uniform=as.numeric(abs(grid(d1,h))<1),
                            Triangle=pmax(1-grid(d1,h)^2,0),
                            Quadratic=pmax(1-grid(d1,h)^2,0)^2,
                            Cubic=pmax(1-grid(d1,h)^2,0)^3)
   kern2 <- switch(lkern,Uniform=as.numeric(abs(grid(d2,h))<1),
                            Triangle=pmax(1-grid(d2,h)^2,0),
                            Quadratic=pmax(1-grid(d2,h)^2,0)^2,
                            Cubic=pmax(1-grid(d2,h)^2,0)^3)
   kern <- outer(kern1,kern2,"*")
       fftkern <- fft(kern)
       sumkern <- sum(kern)
       dsumkern <- d1*d2*sumkern
       yhat<-Re(fft(fft(yy) * fftkern,inv=TRUE))/dsumkern
       yhat1<-Re(fft(fft(ytheta) * fftkern,inv=TRUE))/dsumkern
       yhat2<-Re(fft(fft(ytheta^2) * fftkern,inv=TRUE))/dsumkern
      list(theta=yhat[indx,indy],bi=sumkern,z1=yhat1[indx,indy],z2=yhat2[indx,indy])
}
###########################################################################
#
#   nonadaptive 1D -- 3D smoothing on a grid (kernel supported on (-1,1))
#
###########################################################################
ckernsm<-function (y, h = 1, lkern="Triangle")
{
    extend.y <- function(y,h,d){
       if(d==1) dim(y)<-c(length(y),1)
          n <- dim(y)[1]
	  h <- min(h,n%/%2)
          nn <- nextn(n+2*h)
	  yy <- matrix(0,dim(y)[2],nn)
	  ih0 <- (nn-n)%/%2
	  ih1 <- nn-ih0-n
	  ind <- (ih0+1):(ih0+n)
	  yy[,ind] <- t(y)
	  yy[,1:ih0] <- t(y[ih0:1,])
	  yy[,(nn-ih1+1):nn] <- t(y[n:(n-ih1+1),])
list(yy=t(yy),ind=ind)
}	
    grid <- function(d,h) {
        d0 <- d%/%2 + 1
        gd <- seq(0, 1, length = d0)
        if (2 * d0 == d + 1)
            gd <- c(gd, -gd[d0:2],)
        else gd <- c(gd, -gd[(d0 - 1):2])
        gd/2/h*d
    }
    dy <- dim(y)
    if (is.null(dy))
    dy <- length(y)
    d <- length(dy)
    if(length(h)==1) h <- rep(h,d)
    if(length(h) != d) stop("Incompatible length of bandwidth vector h")
    if(d==1){
       z<-extend.y(y,h[1],1)
       yy <- z$yy
       dyy <- length(yy)
       kern <- switch(lkern,Uniform=as.numeric(abs(grid(dyy,h[1]))<1),
                            Triangle=pmax(1-grid(dyy,h[1])^2,0),
                            Quadratic=pmax(1-grid(dyy,h[1])^2,0)^2,
                            Cubic=pmax(1-grid(dyy,h[1])^2,0)^3)/
               switch(lkern,h[1]*beta(.5,switch(lkern,Uniform=1,
                                                 Triangle=2,
                                                 Quadratic=3,
                                                 Cubic=4)))
       bi <- sum(kern)
       yhat<-Re(fft(fft(yy) * fft(kern),inv=TRUE))[z$ind]/dyy/bi
       bi <- bi*switch(lkern,h[1]*beta(.5,switch(lkern,Uniform=1,
                                                 Triangle=2,
                                                 Quadratic=3,
                                                 Cubic=4)))
    }
    if(d==2){
       z<-extend.y(y,h[1],2)
       yy <- z$yy
       dyy1 <- dim(yy)[1]
       kern1 <- switch(lkern,Uniform=as.numeric(abs(grid(dyy1,h[1]))<1),
                            Triangle=pmax(1-grid(dyy1,h[1])^2,0),
                            Quadratic=pmax(1-grid(dyy1,h[1])^2,0)^2,
                            Cubic=pmax(1-grid(dyy1,h[1])^2,0)^3)/
               switch(lkern,h[1]*beta(.5,switch(lkern,Uniform=1,
                                                 Triangle=2,
                                                 Quadratic=3,
                                                 Cubic=4)))
       yhat<-t(Re(mvfft(mvfft(yy) * fft(kern1),inv=TRUE))[z$ind,]/dyy1/sum(kern1))
       z<-extend.y(yhat,h[2],2)
       yy <- z$yy
       dyy2 <- dim(yy)[1]
       kern2 <- switch(lkern,Uniform=as.numeric(abs(grid(dyy2,h[2]))<1),
                            Triangle=pmax(1-grid(dyy2,h[2])^2,0),
                            Quadratic=pmax(1-grid(dyy2,h[2])^2,0)^2,
                            Cubic=pmax(1-grid(dyy2,h[2])^2,0)^3)/
               switch(lkern,h[2]*beta(.5,switch(lkern,Uniform=1,
                                                 Triangle=2,
                                                 Quadratic=3,
                                                 Cubic=4)))
       yhat<-t(Re(mvfft(mvfft(yy) * fft(kern2),inv=TRUE))[z$ind,]/dyy2/sum(kern2))
       bi <- sum(outer(kern1,kern2))*switch(lkern,h[1]*h[2]*beta(.5,switch(lkern,Uniform=1,
                                                 Triangle=2,
                                                 Quadratic=3,
                                                 Cubic=4))^2)
    }
    if(d==3){
      dim(y) <- c(dy[1],dy[2]*dy[3])
      z<-extend.y(y,h[1],2)
      yy <- z$yy
      dyy1 <- dim(yy)[1]
      kern1 <- switch(lkern,Uniform=as.numeric(abs(grid(dyy1,h[1]))<1),
                            Triangle=pmax(1-grid(dyy1,h[1])^2,0),
                            Quadratic=pmax(1-grid(dyy1,h[1])^2,0)^2,
                            Cubic=pmax(1-grid(dyy1,h[1])^2,0)^3)/
               switch(lkern,h[1]*beta(.5,switch(lkern,Uniform=1,
                                                 Triangle=2,
                                                 Quadratic=3,
                                                 Cubic=4)))
      yhat<-Re(mvfft(mvfft(yy) * fft(kern1),inv=TRUE))[z$ind,]/dyy1/sum(kern1)
      dim(yhat) <- dy
      yhat <- aperm(yhat,c(2,1,3))
      dim(yhat) <- c(dy[2],dy[1]*dy[3])
      z<-extend.y(yhat,h[2],2)
      yy <- z$yy
      dyy2 <- dim(yy)[1]
      kern2 <- switch(lkern,Uniform=as.numeric(abs(grid(dyy2,h[2]))<1),
                            Triangle=pmax(1-grid(dyy2,h[2])^2,0),
                            Quadratic=pmax(1-grid(dyy2,h[2])^2,0)^2,
                            Cubic=pmax(1-grid(dyy2,h[2])^2,0)^3)/
               switch(lkern,h[2]*beta(.5,switch(lkern,Uniform=1,
                                                 Triangle=2,
                                                 Quadratic=3,
                                                 Cubic=4)))
      yhat<-Re(mvfft(mvfft(yy) * fft(kern2),inv=TRUE))[z$ind,]/dyy2/sum(kern2)
      dim(yhat) <- c(dy[2],dy[1],dy[3])
      yhat <- aperm(yhat,c(3,2,1))
      dim(yhat) <- c(dy[3],dy[1]*dy[2])
      z<-extend.y(yhat,h[3],2)
      yy <- z$yy
      dyy3 <- dim(yy)[1]
      kern3 <- switch(lkern,Uniform=as.numeric(abs(grid(dyy3,h[3]))<1),
                            Triangle=pmax(1-grid(dyy3,h[3])^2,0),
                            Quadratic=pmax(1-grid(dyy3,h[3])^2,0)^2,
                            Cubic=pmax(1-grid(dyy3,h[3])^2,0)^3)/
               switch(lkern,h[2]*beta(.5,switch(lkern,Uniform=1,
                                                 Triangle=2,
                                                 Quadratic=3,
                                                 Cubic=4)))
      yhat<-Re(mvfft(mvfft(yy) * fft(kern3),inv=TRUE))[z$ind,]/dyy3/sum(kern3)
      dim(yhat) <- c(dy[3],dy[1],dy[2])
      yhat <- aperm(yhat,c(2,3,1))
      bi <- sum(outer(outer(kern1,kern2),kern3))*switch(lkern,h[1]*h[2]*h[3]*beta(.5,switch(lkern,Uniform=1,
                                                 Triangle=2,
                                                 Quadratic=3,
                                                 Cubic=3))^4)
      }
      bi <- array(bi,dim(y))
      list(theta=yhat,bi=bi)
}
###########################################################################
#
#   nonadaptive 1D -- 3D smoothing on a grid (Gaussian kernel)
#
###########################################################################
gkernsm<-function (y, h = 1)
{
    extend.y <- function(y,h,d){
       if(d==1) dim(y)<-c(length(y),1)
          n <- dim(y)[1]
	  h <- min(h,n%/%2)
          nn <- nextn(n+6*h)
	  yy <- matrix(0,dim(y)[2],nn)
	  ih0 <- (nn-n)%/%2
	  ih1 <- nn-ih0-n
	  ind <- (ih0+1):(ih0+n)
	  yy[,ind] <- t(y)
	  yy[,1:ih0] <- t(y[ih0:1,])
	  yy[,(nn-ih1+1):nn] <- t(y[n:(n-ih1+1),])
list(yy=t(yy),ind=ind)
}	
    grid <- function(d) {
        d0 <- d%/%2 + 1
        gd <- seq(0, 1, length = d0)
        if (2 * d0 == d + 1)
            gd <- c(gd, -gd[d0:2],)
        else gd <- c(gd, -gd[(d0 - 1):2])
        gd
    }
    dy <- dim(y)
    if (is.null(dy))
    dy <- length(y)
    d <- length(dy)
    if(length(h)==1) h <- rep(h,d)
    if(length(h) != d) stop("Incompatible length of bandwidth vector h")
    if(d==1){
       z<-extend.y(y,h[1],1)
       yy <- z$yy
       dyy <- length(yy)
       kern <- dnorm(grid(dyy), 0, 2 * h[1]/dyy)
       bi <- sum(kern)
       yhat<-Re(fft(fft(yy) * fft(kern),inv=TRUE))[z$ind]/dyy/bi
       bi <- bi/dnorm(0,0,2 * h[1]/dyy)
    }
    if(d==2){
       z<-extend.y(y,h[1],2)
       yy <- z$yy
       dyy1 <- dim(yy)[1]
       kern1 <- dnorm(grid(dyy1), 0, 2 * h[1]/dyy1)
       yhat<-t(Re(mvfft(mvfft(yy) * fft(kern1),inv=TRUE))[z$ind,]/dyy1/sum(kern1))
       z<-extend.y(yhat,h[2],2)
       yy <- z$yy
       dyy2 <- dim(yy)[1]
       kern2 <- dnorm(grid(dyy2), 0, 2 * h[2]/dyy2)
       yhat<-t(Re(mvfft(mvfft(yy) * fft(kern2),inv=TRUE))[z$ind,]/dyy2/sum(kern2))
       bi <- sum(outer(kern1,kern2))/dnorm(0,0,2 * h[1]/dyy1)/dnorm(0,0,2 * h[2]/dyy2)
    }
    if(d==3){
      dim(y) <- c(dy[1],dy[2]*dy[3])
      z<-extend.y(y,h[1],2)
      yy <- z$yy
      dyy1 <- dim(yy)[1]
      kern1 <- dnorm(grid(dyy1), 0, 2 * h[1]/dyy1)
      yhat<-Re(mvfft(mvfft(yy) * fft(kern1),inv=TRUE))[z$ind,]/dyy1/sum(kern1)
      dim(yhat) <- dy
      yhat <- aperm(yhat,c(2,1,3))
      dim(yhat) <- c(dy[2],dy[1]*dy[3])
      z<-extend.y(yhat,h[2],2)
      yy <- z$yy
      dyy2 <- dim(yy)[1]
      kern2 <- dnorm(grid(dyy2), 0, 2 * h[2]/dyy2)
      yhat<-Re(mvfft(mvfft(yy) * fft(kern2),inv=TRUE))[z$ind,]/dyy2/sum(kern2)
      dim(yhat) <- c(dy[2],dy[1],dy[3])
      yhat <- aperm(yhat,c(3,2,1))
      dim(yhat) <- c(dy[3],dy[1]*dy[2])
      z<-extend.y(yhat,h[3],2)
      yy <- z$yy
      dyy3 <- dim(yy)[1]
      kern3 <- dnorm(grid(dyy3), 0, 2 * h[3]/dyy3)
      yhat<-Re(mvfft(mvfft(yy) * fft(kern3),inv=TRUE))[z$ind,]/dyy3/sum(kern3)
      dim(yhat) <- c(dy[3],dy[1],dy[2])
      yhat <- aperm(yhat,c(2,3,1))
      bi <- sum(outer(outer(kern1,kern2),kern3))/dnorm(0,0,2 * h[1]/dyy1)/dnorm(0,0,2 * h[2]/dyy2)/dnorm(0,0,2 * h[3]/dyy3)
      }
      bi <- array(bi,dim(y))
      list(theta=yhat,bi=bi)
}
Varcor<-function(lkern,h,d=1){
#
#   Calculates a correction for the variance estimate obtained by (IQRdiff(y)/1.908)^2
#
#   in case of colored noise that was produced by smoothing with lkern and bandwidth h
#
if(lkern=="Gaussian") h<-h/2.3548
ih<-switch(lkern,Gaussian=trunc(4*h)+1,trunc(h)+1)
dx<-2*ih+1
x<- ((-ih):ih)/h
if(d==2) x<-sqrt(outer(x^2,x^2,"+"))
if(d==3) x<-sqrt(outer(x^2,outer(x^2,x^2,"+"),"+"))
penl<-switch(lkern,Triangle=pmax(0,1-x^2),
                   Uniform=as.numeric(abs(x)<=1),
                   Quadratic=pmax(0,1-x^2)^2,
                   Cubic=pmax(0,1-x^2)^3,
                   Gaussian=dnorm(x))
2*sum(penl)^2/sum(diff(penl)^2)
}
Varcor.gauss<-function(h){
#
#   Calculates a correction for the variance estimate obtained by (IQRdiff(y)/1.908)^2
#
#   in case of colored noise that was produced by smoothing with lkern and bandwidth h
#
h<-pmax(h/2.3548,1e-5)
ih<-trunc(4*h)+1
dx<-2*ih+1
d<-length(h)
penl <- dnorm(((-ih[1]):ih[1])/h[1])
if(d==2) penl <- outer(penl,dnorm(((-ih[2]):ih[2])/h[2]),"*")
if(d==3) penl <- outer(penl,outer(dnorm(((-ih[2]):ih[2])/h[2]),dnorm(((-ih[3]):ih[3])/h[3]),"*"),"*")
2*sum(penl)^2/sum(diff(penl)^2)
}

SpatialCorr<-function(lkern,h,d=1){
#
#   Calculates the correlation of 
#
#   colored noise that was produced by smoothing with lkern and bandwidth h
#
#  !!! the result is not monotone in h for   lkern="Triangle" (all d) and lkern="Uniform" (d>1)
#
if(lkern=="Gaussian") h<-h/2.3548
ih<-switch(lkern,Gaussian=trunc(4*h+1),trunc(h)+1)
dx<-2*ih+1
x<- ((-ih):ih)/h
if(d==2) x<-sqrt(outer(x^2,x^2,"+"))
if(d==3) x<-sqrt(outer(x^2,outer(x^2,x^2,"+"),"+"))
penl<-as.vector(switch(lkern,Triangle=pmax(0,1-x^2),
                   Uniform=as.numeric(abs(x)<=1),
                   Quadratic=pmax(0,1-x^2)^2,
                   Cubic=pmax(0,1-x^2)^3,
                   Gaussian=dnorm(x)))
dim(penl)<-rep(dx,d)
if(d==1) z<-sum(penl[-1]*penl[-dx])/sum(penl^2)
if(d==2) z<-sum(penl[-1,]*penl[-dx,])/sum(penl^2)
if(d==3) z<-sum(penl[-1,,]*penl[-dx,,])/sum(penl^2)
z
}

SpatialCorr.gauss<-function(h){
#
#   Calculates the correlation of 
#
#   colored noise that was produced by smoothing with "gaussian" kernel and bandwidth h
#
#   Result does not depend on d for "Gaussian" kernel !!
#
h<-h/2.3548
ih<-trunc(4*h+1)
dx<-2*ih+1
penl<-dnorm(((-ih):ih)/h)
sum(penl[-1]*penl[-dx])/sum(penl^2)
}

Spatialvar<-function(lkern,lkern0,h,h0,d){
#
#   Calculates the factor of variance reduction obtained at bandwidth h in 
#
#   case of colored noise that was produced by smoothing with lkern0 and bandwidth h0
#
#   Spatialvariance(lkern,h,h0,d)/Spatialvariance(lkern,h,1e-5,d) gives the 
#   a factor for lambda to be used with bandwidth h 
#
if(lkern=="Gaussian") h<-h/2.3548
ih<-switch(lkern,Gaussian=trunc(4*h),trunc(h))
ih<-max(1,ih)
dx<-2*ih+1
x<- ((-ih):ih)/h
if(d==2) x<-sqrt(outer(x^2,x^2,"+"))
if(d==3) x<-sqrt(outer(x^2,outer(x^2,x^2,"+"),"+"))
penl<-switch(lkern,Triangle=pmax(0,1-x^2),
                   Uniform=as.numeric(abs(x)<=1),
                   Quadratic=pmax(0,1-x^2)^2,
                   Cubic=pmax(0,1-x^2)^3,
                   Gaussian=dnorm(x))
dim(penl)<-rep(dx,d)
if(lkern0=="Gaussian") h0<-h0/2.3548
ih<-switch(lkern0,Gaussian=trunc(4*h0),trunc(h0))
ih<-max(1,ih)
dx0<-2*ih+1
x<- ((-ih):ih)/h0
if(d==2) x<-sqrt(outer(x^2,x^2,"+"))
if(d==3) x<-sqrt(outer(x^2,outer(x^2,x^2,"+"),"+"))
penl0<-switch(lkern0,Triangle=pmax(0,1-x^2),
                   Uniform=as.numeric(abs(x)<=1),
                   Quadratic=pmax(0,1-x^2)^2,
                   Cubic=pmax(0,1-x^2)^3,
                   Gaussian=dnorm(x))
dim(penl0)<-rep(dx0,d)
penl0<-penl0/sum(penl0)
dz<-dx+dx0-1
z<-array(0,rep(dz,d))
if(d==1){
for(i1 in 1:dx0) {
ind1<-c(0:(i1-1),(dz-dx0+i1):dz+1)
ind1<-ind1[ind1<=dz][-1]
z[-ind1]<-z[-ind1]+penl*penl0[i1]
}
} else if(d==2){
for(i1 in 1:dx0) for(i2 in 1:dx0){
ind1<-c(0:(i1-1),(dz-dx0+i1):dz+1)
ind1<-ind1[ind1<=dz][-1]
ind2<-c(0:(i2-1),(dz-dx0+i2):dz+1)
ind2<-ind2[ind2<=dz][-1]
z[-ind1,-ind2]<-z[-ind1,-ind2]+penl*penl0[i1,i2]
}
} else if(d==3){
for(i1 in 1:dx0) for(i2 in 1:dx0) for(i3 in 1:dx0){
ind1<-c(0:(i1-1),(dz-dx0+i1):dz+1)
ind1<-ind1[ind1<=dz][-1]
ind2<-c(0:(i2-1),(dz-dx0+i2):dz+1)
ind2<-ind2[ind2<=dz][-1]
ind3<-c(0:(i3-1),(dz-dx0+i3):dz+1)
ind3<-ind3[ind3<=dz][-1]
z[-ind1,-ind2,-ind3]<-z[-ind1,-ind2,-ind3]+penl*penl0[i1,i2,i3]
}
}
sum(z^2)/sum(z)^2
}

Spatialvar.gauss<-function(h,h0,d){
#
#   Calculates the factor of variance reduction obtained for Gaussian Kernel and bandwidth h in 
#
#   case of colored noise that was produced by smoothing with Gaussian kernel and bandwidth h0
#
#   Spatialvariance(lkern,h,h0,d)/Spatialvariance(lkern,h,1e-5,d) gives the 
#   a factor for lambda to be used with bandwidth h 
#
h0 <- max(1e-5,h0)
h<-h/2.3548
if(length(h)==1) h<-rep(h,d)
ih<-trunc(4*h)
ih<-pmax(1,ih)
dx<-2*ih+1
penl<-dnorm(((-ih[1]):ih[1])/h[1])
if(d==2) penl<-outer(dnorm(((-ih[1]):ih[1])/h[1]),dnorm(((-ih[2]):ih[2])/h[2]),"*")
if(d==3) penl<-outer(dnorm(((-ih[1]):ih[1])/h[1]),outer(dnorm(((-ih[2]):ih[2])/h[2]),dnorm(((-ih[3]):ih[3])/h[3]),"*"),"*")
dim(penl)<-dx
h0<-h0/2.3548
if(length(h0)==1) h0<-rep(h0,d)
ih<-trunc(4*h0)
ih<-pmax(1,ih)
dx0<-2*ih+1
x<- ((-ih[1]):ih[1])/h0[1]
penl0<-dnorm(((-ih[1]):ih[1])/h0[1])
if(d==2) penl0<-outer(dnorm(((-ih[1]):ih[1])/h0[1]),dnorm(((-ih[2]):ih[2])/h0[2]),"*")
if(d==3) penl0<-outer(dnorm(((-ih[1]):ih[1])/h0[1]),outer(dnorm(((-ih[2]):ih[2])/h0[2]),dnorm(((-ih[3]):ih[3])/h0[3]),"*"),"*")
dim(penl0)<-dx0
penl0<-penl0/sum(penl0)
dz<-dx+dx0-1
z<-array(0,dz)
if(d==1){
for(i1 in 1:dx0) {
ind1<-c(0:(i1-1),(dz-dx0+i1):dz+1)
ind1<-ind1[ind1<=dz][-1]
z[-ind1]<-z[-ind1]+penl*penl0[i1]
}
} else if(d==2){
for(i1 in 1:dx0[1]) for(i2 in 1:dx0[2]){
ind1<-c(0:(i1-1),(dz[1]-dx0[1]+i1):dz[1]+1)
ind1<-ind1[ind1<=dz[1]][-1]
ind2<-c(0:(i2-1),(dz[2]-dx0[2]+i2):dz[2]+1)
ind2<-ind2[ind2<=dz[2]][-1]
z[-ind1,-ind2]<-z[-ind1,-ind2]+penl*penl0[i1,i2]
}
} else if(d==3){
for(i1 in 1:dx0[1]) for(i2 in 1:dx0[2]) for(i3 in 1:dx0[3]){
ind1<-c(0:(i1-1),(dz[1]-dx0[1]+i1):dz[1]+1)
ind1<-ind1[ind1<=dz[1]][-1]
ind2<-c(0:(i2-1),(dz[2]-dx0[2]+i2):dz[2]+1)
ind2<-ind2[ind2<=dz[2]][-1]
ind3<-c(0:(i3-1),(dz[3]-dx0[3]+i3):dz[3]+1)
ind3<-ind3[ind3<=dz[3]][-1]
z[-ind1,-ind2,-ind3]<-z[-ind1,-ind2,-ind3]+penl*penl0[i1,i2,i3]
}
}
sum(z^2)/sum(z)^2
}

geth.gauss<-function(corr,step=1.01){
#   get the   bandwidth for lkern corresponding to a given correlation
# 
#  keep it simple result does not depend on d
#
  if (corr < 0.1) {
    h <- 1e-5
  } else { 
    h <- .8
    z <- 0
    while (z<corr) {
      h <- h*step
      z <- get.corr.gauss(h,interv=2)
    }
    h <- h/step
  }
  h
}

get3Dh.gauss<-function(vred,h0,vwghts,step=1.01){
  h0 <- pmax(h0,1e-5)
  n<-length(vred)
vred1<-vred
h<-.5/vwghts
fixed<-rep(FALSE,length(vred))
while(any(!fixed)){
ind<-(1:n)[!fixed][vred[!fixed]>=Spatialvar.gauss(h,1e-5,3)]
vred1[ind]<-Spatialvar.gauss(h,h0,3)
fixed[ind]<-TRUE
h<-h*step
}
hvred<-matrix(0,3,n)
hh<-.01/vwghts
h<-h0
fixed<-rep(FALSE,length(vred))
while(any(!fixed)){
ind<-(1:n)[!fixed][vred1[!fixed]>=Spatialvar.gauss(h,1e-5,3)]
hvred[,ind]<-h
fixed[ind]<-TRUE
hh<-hh*step
h<-sqrt(h0^2+hh^2)
}
t(hvred)
}

get.corr.gauss <- function(h,interv=1) {
    #
    #   Calculates the correlation of 
    #   colored noise that was produced by smoothing with "gaussian" kernel and bandwidth h
    #   Result does not depend on d for "Gaussian" kernel !!
    h <- h/2.3548*interv
    ih <- trunc(4*h+ 2*interv-1)
    dx <- 2*ih+1
    penl <- dnorm(((-ih):ih)/h)
    sum(penl[-(1:interv)]*penl[-((dx-interv+1):dx)])/sum(penl^2)
}
###########################################################################################
#
#       gfft:   smoothing data on a 1D, 2D or 3D regular grid depending on dim(y) 
#               bandwidth h in standard dev. on grid units 
#
##########################################################################################
gfft<-function (y, h = 1)
{
    extend.y <- function(y,h,d){
       if(d==1) dim(y)<-c(length(y),1)
          n <- dim(y)[1]
	  h <- min(h,n%/%2)
          nn <- nextn(n+6*h)
	  yy <- matrix(0,dim(y)[2],nn)
	  ih0 <- (nn-n)%/%2
	  ih1 <- nn-ih0-n
	  ind <- (ih0+1):(ih0+n)
	  yy[,ind] <- t(y)
	  yy[,1:ih0] <- t(y[ih0:1,])
	  yy[,(nn-ih1+1):nn] <- t(y[n:(n-ih1+1),])
list(yy=t(yy),ind=ind)
}	
    grid <- function(d) {
        d0 <- d%/%2 + 1
        gd <- seq(0, 1, length = d0)
        if (2 * d0 == d + 1)
            gd <- c(gd, -gd[d0:2],)
        else gd <- c(gd, -gd[(d0 - 1):2])
        gd
    }
    dy <- dim(y)
    if (is.null(dy))
    dy <- length(y)
    if(length(dy)==1){
       z<-extend.y(y,h,1)
       yy <- z$yy
       dy <- length(yy)
       kern <- dnorm(grid(dy), 0, 2 * h/dy)
       yhat<-Re(fft(fft(yy) * fft(kern),inv=TRUE))[z$ind]/dy/sum(kern)
    }
    if(length(dy)==2){
       z<-extend.y(y,h,2)
       yy <- z$yy
       dy <- dim(yy)
      kern <- dnorm(grid(dy[1]), 0, 2 * h/dy[1])
      yhat<-t(Re(mvfft(mvfft(yy) * fft(kern),inv=TRUE))[z$ind,]/dy[1]/sum(kern))
       z<-extend.y(yhat,h,2)
       yy <- z$yy
       dy <- dim(yy)
      kern <- dnorm(grid(dy[1]), 0, 2 * h/dy[1])
      yhat<-t(Re(mvfft(mvfft(yy) * fft(kern),inv=TRUE))[z$ind,]/dy[1]/sum(kern))
    }
    if(length(dy)==3){
      kern <- dnorm(grid(dy[1]), 0, 2 * h/dy[1])
      dim(y) <- c(dy[1],dy[2]*dy[3])
      yhat<-Re(mvfft(mvfft(y) * fft(kern),inv=TRUE))/dy[1]
      dim(yhat) <- dy
      yhat <- aperm(yhat,c(2,1,3))
      dim(yhat) <- c(dy[2],dy[1]*dy[3])
      kern <- dnorm(grid(dy[2]), 0, 2 * h/dy[2])
      yhat<-Re(mvfft(mvfft(yhat)* fft(kern),inv=TRUE))/dy[2]
      dim(yhat) <- c(dy[2],dy[1],dy[3])
      yhat <- aperm(yhat,c(3,2,1))
      dim(yhat) <- c(dy[3],dy[1]*dy[2])
      kern <- dnorm(grid(dy[3]), 0, 2 * h/dy[3])
      yhat<-Re(mvfft(mvfft(yhat)* fft(kern),inv=TRUE))/dy[3]
      dim(yhat) <- c(dy[3],dy[1],dy[2])
      yhat <- aperm(yhat,c(2,3,1))
      }
      yhat
}
