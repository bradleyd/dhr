# Router

### Distributed HTTP server

This is scratch code for upcoming meetup.


The idea is to distribute HTTP calls to different nodes.  For example,
lets say your web applicaiton has a busy '/about' endpoint, but '/login' is not as busy.  Why have them on the same host?  Why not have them run on different nodes (unikernels?).  The benefit of this is, one could scale up '/about' nodes while not needing to make the rest of the applicaiton feel the pain.  Imagine spinning up new nodes--tiny bits of code--for busy times, instead of spinning up whole instances of your application.
