local fs = require("@lune/fs")

local generator = fs.readFile("scripts/generate-pipilabu-shiba.py")
local direction = string.lower(fs.readFile("docs/CHARACTER_ART_DIRECTION.md"))
local ledger = string.lower(fs.readFile("docs/IDEA_LEDGER.md"))

-- GOLDEN-CHANGE: Leo's 2026-08-09 video frames supersede the v4 side-ear
-- candidate. V6 must preserve the video-turnaround's swallowed folds, distinct
-- owner/customer architectures, and a hard Roblox per-mesh import budget;
-- importing successfully is still not an approval signal.
-- GOLDEN-CHANGE: v6 replaces the rejected v5 coordinates with the exact
-- video-turnaround silhouette and adds the 20k triangle failure boundary.
-- GOLDEN-CHANGE: Studio review of v7 exposed voxel terracing and detached
-- modular parts that Blender's beauty render concealed. V8 changes the
-- acceptance contract to regular smooth topology, one continuous customer
-- shell, flat-safe synthetic normals, and owner-only lateral ear folds that do
-- not break the crown. The old v6 coordinates remain as archived generator
-- history, but they are no longer the promoted candidate path.
assert(string.find(generator, 'SCRIPT_VERSION = "3.5.1"', 1, true), "Studio-equivalent generator version changed unexpectedly")
assert(string.find(generator, "def smooth_uv_shell(", 1, true), "regular Studio-stable shell builder is missing")
assert(string.find(generator, "def shape_customer_shell(", 1, true), "continuous customer shell deformation is missing")
assert(string.find(generator, 'body = smooth_uv_shell("MainFusedBody", (0, 0.13, 0.40)', 1, true), "v8 continuous customer body plan is missing")
assert(string.find(generator, 'body = smooth_uv_shell("MainFusedBody", (0, 0.05, 0.93)', 1, true), "v8 owner body plan is missing")
assert(string.find(generator, '(0.64 * sign, -0.305, 1.505)', 1, true), "owner lateral ear fold placement is missing")
assert(not string.find(generator, '(0.325 * sign, -0.890, 0.615)', 1, true), "rejected customer ear knobs returned")
assert(string.find(generator, 'MODEL_VERSION in {"v7", "v8"}', 1, true), "flat-safe v8 synthetic normal policy is missing")
assert(string.find(generator, '"No top-ear geometry; rounded crown is absolute"', 1, true), "v8 no-top-ear policy is missing")
assert(string.find(generator, "REJECTED_BY_LEO_2026_08_09", 1, true), "rejected v8 must never regain promotion status")
assert(string.find(generator, '((-0.36, -0.58, 0.69), (0.075, 0.060, 0.055))', 1, true), "customer left swallowed ear root is missing")
assert(string.find(generator, '((0.36, -0.58, 0.69), (0.075, 0.060, 0.055))', 1, true), "customer right swallowed ear root is missing")
assert(string.find(generator, '((-0.65, -0.25, 1.63), (0.085, 0.065, 0.070))', 1, true), "owner left swallowed ear root is missing")
assert(string.find(generator, '((0.65, -0.25, 1.63), (0.085, 0.065, 0.070))', 1, true), "owner right swallowed ear root is missing")
assert(string.find(generator, '((0, 0.29, 0.43), (0.54, 0.88, 0.34))', 1, true), "customer long-backed body plan is missing")
assert(string.find(generator, '((0, 0.09, 0.86), (1.03, 0.76, 0.83))', 1, true), "owner grounded body plan is missing")
assert(string.find(generator, 'meshes_over_20000_triangles', 1, true), "Roblox per-mesh triangle guard is missing")
assert(not string.find(generator, '((-0.56, -0.02, 2.00), (0.22, 0.17, 0.34))', 1, true), "rejected upper-left ear mass returned")
assert(not string.find(generator, '((0.56, -0.02, 2.00), (0.22, 0.17, 0.34))', 1, true), "rejected upper-right ear mass returned")
assert(string.find(direction, "no readable upright top-ear triangles", 1, true), "canonical no-top-ear rule is missing")
assert(string.find(direction, "tiny, low, quadrupedal shiba/loaf anatomy", 1, true), "customer video anatomy is missing")
assert(string.find(ledger, "one enormous natural shiba seller", 1, true), "idea ledger does not carry the owner scale target")
assert(string.find(ledger, "tiny low quadrupedal shiba/loaf customers", 1, true), "idea ledger does not carry the line anatomy target")

print("Pipi Labu character silhouette contract passed circular-crown and tiny-side-ear checks")
