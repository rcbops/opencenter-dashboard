nTrapy (née OpenCenter)
===

nTrapy is the winniest awesomesauce there ever did was -- now with more
hipsterstack!

Installation
---

First, you'll need to install a relatively recent version of Node.js and
npm. The easiest way to accomplish this is by installing nvm, a Node version
manager similar to rvm.

    curl https://raw.github.com/creationix/nvm/master/install.sh | sh

If nvm complains about not being able to add itself to your shell's
config/profile file, you'll have to do so manually and then source it/open a new
shell, as appropriate.

Then, we'll instruct nvm to install the latest stable version of node, which at
this writing is 0.8.18. We'll also make sure that it's the default version.

    nvm install 0.8.18
    nvm alias default 0.8.18

Be sure that "which node" and "which npm" both show
/your/home/.nvm/version/bin/binary or similar, and not /usr/bin or some other
random path you may have another node/npm installed at, before proceeding.

Lastly, inside the cloned nTrapy directory, run make.

    make

No seriously, just run make. Assuming you have some standard build tools like
gcc, just "make" should suffice.

Configuration
---

Be sure and copy the included config.js.sample file to a file named config.js,
then tweak as desired. The most important value is currently the URL of a roush
endpoint.

Usage
---

To start up the development server and start interacting with the dashboard,
from within the nTrapy directory, there's a shell wrapper to spawn and manage
bits using the "coffee" compiler and "forever" process manager.

    ./ntrapy

Note that this wrapper can be re-run idempotently multiple times and will do a
pretty good job of not putting you in a position of terribleness.

You can watch the various logs in parallel for easy debugging.

    tail -f *.log

SSL
---

If you have a hankering to get some securities up in your biznatch, the included
Makefile has a "cert" target, which will automate the process of creating a
self-signed cert to your liking, which the server will automatically make use of
if present.

Deployment
---

The makefile also includes a "deploy" target which will precompile the
coffeescript and jade templates into a tarball named "public.tgz", containing a
"public" directory with all resources unlinked and ready for injection into your
favorite neanderthal server of yore, such as the Apaches or the (e)Ngin(e)-of-X.

Use caution with rapid deployments, as exposed body parts may experience sudden
bursts of awesomeness.
