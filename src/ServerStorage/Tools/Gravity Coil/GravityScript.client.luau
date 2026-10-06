-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiler will be improved VERY SOON!
-- Decompiled with Konstant V2.1, a fast Luau decompiler made in Luau by plusgiant5 (https://discord.gg/wyButjTMhM)
-- Decompiled on 2025-06-05 12:15:54
-- Luau version 6, Types version 3
-- Time taken: 0.000519 seconds

local Parent = script.Parent
Parent.Equipped:Connect(function() -- Line 4
	workspace.Gravity = 29.429999999999996
end)
Parent.Unequipped:Connect(function() -- Line 11
	workspace.Gravity = 196.2
end)