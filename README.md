OpenCenter Dashboard
===

The OpenCenter Dashboard is the winniest awesomesauce there ever did was -- now
with more hipsterstack!

Installation
---

First, you'll need to install a relatively recent version of Node.js and
npm. The easiest way to accomplish this is by installing nvm, a Node version
manager similar to rvm.

    curl https://raw.github.com/creationix/nvm/master/install.sh | sh

If nvm complains about not being able to add itself to your shell's
config/profile file, you'll have to do so manually and then source it/open a
new shell, as appropriate.

Then, we'll instruct nvm to install the latest stable version of node, which at
this writing is 0.8.18. We'll also make sure that it's the default version.

    nvm install 0.8.18
    nvm alias default 0.8.18

Before proceeding, ensure that `which node` and `which npm` both show
`/your/home/.nvm/version/bin/binary` or similar, and not `/usr/bin` or some
other random path in which you may have another node/npm installed.

Lastly, inside the cloned dashboard directory, run make.

    make

This will install and prepare the minimum dependencies to run the dashboard
using the Node.js backend. Alternatively, you can install the full development
stack.

    make dev

This will allow you to interact with Bower and the full tooling of Node deps.

Configuration
---

Be sure and copy the included `config.json.sample` file to a file named
`config.json`, then tweak as desired. The most important value is currently the
URL of an OpenCenter endpoint.

Usage
---

To start up the development server and start interacting with the dashboard,
from within the dashboard directory, there's a shell wrapper to spawn and
manage bits using the "coffee" script compiler, "jade" template compiler and
"node-dev" for managing the primary process.

    ./dashboard

Note that this wrapper can be re-run idempotently multiple times and will do a
pretty good job of not putting you in a position of terribleness.

You can watch the various logs in parallel for easy debugging.

    tail -f *.log

SSL
---

If you have a hankering to get some securities up in your business, the included
makefile has a "cert" target, which will automate the process of creating a
self-signed cert to your liking, which the server will automatically make use of
if present.


Deployment
---

The makefile also includes a `deploy` target which will do the needful in a way
that's fakeroot and package friendly, with all the appropriate resources in
`./public`, ready for injection into your favorite neanderthal server of yore,
such as the Apaches or the (e)Ngin(e)-of-X.

Use caution with rapid deployments, as exposed body parts may experience sudden
bursts of awesomeness.
