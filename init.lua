-- Parallels topology plugin — provision a Parallels VM as a topology.
--
-- A VM is where you black-box test a full-OS target Docker can't contain: a systemd unit, a kernel
-- module, a whole install, a Windows box. This drives `prlctl` via `shell.run` — the same shape as
-- the docker-exec plugins, just a different CLI. It is gated by `requires = { "prlctl" }` in the
-- advertisement (prova.toml), so on a machine without Parallels Desktop it skips cleanly rather than
-- failing deep in a factory.
--
-- STATUS: the STRUCTURE (loads, advertises `vm`, gates on `prlctl`) is proven hermetically in this
-- repo's proofs. The `prlctl` provisioning below runs only where `prlctl` is on PATH — a Parallels
-- host — and is exercised there by the `requires = { "prlctl" }` proof. Verify it on such a host
-- before leaning on it; the surrounding contract is what this incubation nails down.

local parallels = {}

--- Provision a disposable **linked clone** of `opts.image`, start it, wait for the guest to answer,
--- and return a driveable handle. Teardown (stop + delete the clone) is tied to `ctx`, so the base
--- template is never touched and nothing leaks.
---
--- @param ctx   the topology/test context (for `:manage` / `:defer`)
--- @param opts  { image: string, name?: string, timeout?: string }
---              `image` — the base VM template to linked-clone (required)
--- @return      { name: string, run: fun(self, argv: string[]): string, ip: fun(self): string }
function parallels.vm(ctx, opts)
	opts = opts or {}
	local image = opts.image
		or error("parallels.vm: opts.image (a base VM template to linked-clone) is required")

	-- A unique, disposable clone name so concurrent topologies never collide.
	local clone = opts.name or ("prova-" .. image:gsub("%W", "-") .. "-" .. tostring(os.time()))

	-- Linked clone → disposable and cheap. Register teardown BEFORE starting, so a failure mid-boot
	-- still cleans up (`stop --kill` and `delete` are idempotent).
	assert(
		shell.run({ "prlctl", "clone", image, "--name", clone, "--linked" }):ok(),
		"prlctl clone " .. image .. " → " .. clone .. " failed"
	)
	ctx:defer(function()
		shell.run({ "prlctl", "stop", clone, "--kill" })
		shell.run({ "prlctl", "delete", clone })
	end)

	assert(shell.run({ "prlctl", "start", clone }):ok(), "prlctl start " .. clone .. " failed")

	-- Readiness: retry an exec until the guest tools answer. Don't sleep — retry the real thing.
	prova.retry(function()
		assert(shell.run({ "prlctl", "exec", clone, "true" }):ok(), "guest not ready")
	end, { timeout = opts.timeout or "120s" })

	local vm = { name = clone }

	--- Exec `argv` inside the guest as root; returns stdout, raises on a non-zero exit.
	function vm:run(argv)
		local cmd = { "prlctl", "exec", self.name }
		for _, a in ipairs(argv) do
			cmd[#cmd + 1] = a
		end
		local r = shell.run(cmd)
		assert(
			r:ok(),
			"guest command failed (" .. table.concat(argv, " ") .. "):\n" .. (r.stderr or "")
		)
		return r.stdout
	end

	--- The guest's first IPv4 on the host-reachable network.
	function vm:ip()
		return (self:run({ "hostname", "-I" }):match("%S+"))
	end

	return vm
end

return parallels
