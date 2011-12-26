# tinderbox

tinderbox is native Mac client for Campfire. 

(Work in progress.)

## About

tinderbox is written with Cocoa, but hosts a [node.js](http://www.nodejs.org/) in server running the background to serve up layout and content over a UNIX Socket. This avoids the nasty side effects of running two copies at the same time or opening up TCP sockets that cause annoying headaches with firewalls and security software. 

Behind the scenes it makes use of [express](http://expressjs.com/), [coffee-script](http://coffeescript.org/), and ejs to render up content inside the app. 

## Motivation

Native campfire apps for the Mac all have serious issues. Very few of them are Open Source so I can't fix them. Campfire is natively a web experience so using a web based framework for interacting with it makes sense but at the same time it's still a not native Cocoa app. 

I could of written this entire in Objective-C, but it's a side project. Writing new OAuth code for Campfire, custom Campfire long polling code, and a bunch of HTML code in Objective-C didn't seem like a good use my time. Using existing Javascript code and libraries for Campfire, rendering HTML with frameworks built to render HTML already, and using a server that can handle long polling really well already (node), this solution really seems to make a lot of sense in my book.

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