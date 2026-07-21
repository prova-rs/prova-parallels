---@meta parallels
--- prova-parallels — provision a Parallels VM as a topology (black-box test a full-OS target Docker
--- can't contain: a systemd unit, a kernel module, a whole install, a Windows box).
---
--- Editor-only type stub for `require("parallels")`: it gives consumers completion and signatures and
--- ships nothing at runtime. Keep it in sync with init.lua's public API.

local parallels = {}

--- Options for `parallels.vm`.
---@class parallels.VmOpts
---@field image string     # base VM template to linked-clone (required)
---@field name? string     # clone name (default: derived, unique)
---@field timeout? string  # readiness timeout, e.g. "120s"

--- A live VM handle returned by `parallels.vm`.
---@class parallels.Vm
---@field name string                          # the clone's name
local Vm = {}

--- Exec `argv` inside the guest as root; returns stdout, raises on a non-zero exit.
---@param argv string[]
---@return string
function Vm:run(argv) end

--- The guest's first IPv4 on the host-reachable network.
---@return string
function Vm:ip() end

--- Provision a disposable linked clone of `opts.image`, start it, wait for the guest to answer, and
--- return a driveable handle. Teardown (stop + delete the clone) is tied to `ctx`.
---@param ctx any
---@param opts parallels.VmOpts
---@return parallels.Vm
function parallels.vm(ctx, opts) end

return parallels
