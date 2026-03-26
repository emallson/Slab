---@class SlabPrivate
local private = select(2, ...)

if not private.util then
    private.util = {}
end

---construct a frame with a child fontstring that can be parented to another frame with clipping enabled
---@return Frame, FontString
function private.util.ClippedFontString(name, parent, fontSize)
    local clipFrame = CreateFrame('Frame', name, parent)
    clipFrame:SetClipsChildren(true)
    local fontString = clipFrame:CreateFontString(name .. 'Text', 'OVERLAY')
    fontString:SetFont(private.font, fontSize, 'OUTLINE')
    fontString:SetPoint('TOPLEFT')
    fontString:SetMaxLines(1)
    return clipFrame, fontString
end