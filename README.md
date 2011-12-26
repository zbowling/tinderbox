# tinderbox

tinderbox is native Mac client for Campfire. 

(Work in progress.)

## About

tinderbox is written with Cocoa, but hosts a [node.js](http://www.nodejs.org/) server running the background to serve up layout and content over a UNIX socket. This avoids the nasty side effects of running two copies at the same time or opening up TCP sockets that cause annoying headaches with firewalls and security software. 

Behind the scenes it makes use of [express](http://expressjs.com/), [coffee-script](http://coffeescript.org/), and ejs to render up content inside the app. 

## Motivation

All the native Campfire apps for the Mac seem to have serious issues. Very few of them are open source so I can't fix them. Campfire is natively a web experience so using a framework that is native to the web and filling in on the details with native Cocoa seemed to be the best option. 

Sure, I could of written this entire in Objective-C, but it's a free-time project. Writing new OAuth code for Campfire and custom Campfire long polling code and a bunch of HTML render code in Objective-C didn't seem like a good use my time. However, using Node behind Cocoa means I can use existing Javascript code and libraries for Campfire, render HTML with frameworks built to render HTML brilliantly already, and use a server that can handle long polling really well. That's a win in my book.  

The javascript code is abstract enough that it could be replaced with a similar native wrapper for other platforms (like Windows and Linux) in the future as well. 

## Building

Running the project should be enough. 

If you want to rebuild node, it's as easy as this:

```bash
  cd vendor/node
  ./configure --without-npm --prefix=$PWD/../../res/node/
```

I remove the `lib/`, `shared/` and `include/` directories and the `bin/node-waf` file because they are not necessary to run just node and bundling adds dead weight. (TODO: automate)

## License

tinderbox uses the MIT license. See LICENSE for more details.