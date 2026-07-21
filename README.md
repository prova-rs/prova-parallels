# prova-parallels

A plugin for [Prova](https://github.com/prova-rs/prova) — provision a Parallels VM as a **topology**,
to black-box test a full-OS target Docker can't contain: a systemd unit, a kernel module, a whole
install, a Windows box.

In Prova a plugin *is* a test suite that also exports a namespace: one `prova.toml` declares the
plugin and runs its own proofs. This repo is that — the factory lives in `init.lua`, its proofs in
`tests/`. It drives `prlctl` through `shell.run` (zero native code) and is gated on `prlctl`, so it
skips cleanly off a Parallels host.

## Use it

Declare it in your project's `prova.toml`, pinned to a released tag, and register the topology it
advertises — passing the base template to clone via `options`:

```toml
[plugins]
parallels = { git = "https://github.com/prova-rs/prova-parallels", tag = "v1" }

[topologies]
vm = { plugin = "parallels", topology = "vm", options = { image = "ubuntu-24.04" } }
```

Then `prova up vm` stands up a VM (and skips cleanly where `prlctl` isn't on PATH). In a test, use the
factory directly behind `requires = { "prlctl" }`:

```lua
local parallels = require("parallels")

prova.test("the guest is Linux", { requires = { "prlctl" } }, function(t)
  local vm = parallels.vm(t, { image = "ubuntu-24.04" })  -- linked-clone, started, torn down with the test
  t:expect(vm:run({ "uname", "-s" })):contains("Linux")
end)
```

## API

`parallels.vm(ctx, { image, name?, timeout? })` → a handle `{ name, run(argv), ip() }`:

- linked-clones `image` (a template in your Parallels library), starts it, waits for the guest;
- `vm:run(argv)` execs in the guest as root and returns stdout;
- `vm:ip()` is the guest's host-reachable IPv4;
- the clone is stopped and deleted on teardown — the base template is never touched.

## Requirements

Parallels Desktop (`prlctl` on PATH) and a base VM template to clone. Gate anything that provisions
with `requires = { "prlctl" }` so it skips where Parallels is absent. The real-provisioning self-test
also reads `PROVA_PARALLELS_IMAGE` (a template name) and skips without it.

## Develop

```bash
prova                        # run the self-test in tests/ (hermetic; VM test skips without prlctl)
prova plugin lint init.lua   # check the plugin conforms to the namespacing grammar
```

The **Test** workflow runs the self-test on every push; the **Release** workflow (dispatched
manually) tags the next version so consumers can pin `prova-rs/prova-parallels@vX.Y.Z`.

MIT licensed.
