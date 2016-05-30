local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local ffi_cdef = ffi.cdef
local ffi_load = ffi.load
local ffi_typeof = ffi.typeof
local ffi_sizeof = ffi.sizeof
local tonumber = tonumber
local assert = assert
local upper = string.upper
local type = type
ffi_cdef [[
typedef uint16_t utf16_t;
typedef uint32_t unicode_t;
typedef int64_t off_t;
 size_t utf8envlocale();
 size_t utf8len(const char* text);
 size_t utf8toupper(const char* input, size_t inputSize, char* target, size_t targetSize, size_t locale, int32_t* errors);
 size_t utf8tolower(const char* input, size_t inputSize, char* target, size_t targetSize, size_t locale, int32_t* errors);
 size_t utf8totitle(const char* input, size_t inputSize, char* target, size_t targetSize, size_t locale, int32_t* errors);
 size_t utf8casefold(const char* input, size_t inputSize, char* target, size_t targetSize, size_t locale, int32_t* errors);
 size_t utf16toutf8(const utf16_t* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t utf32toutf8(const unicode_t* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t widetoutf8(const wchar_t* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t utf8toutf16(const char* input, size_t inputSize, utf16_t* target, size_t targetSize, int32_t* errors);
 size_t utf8toutf32(const char* input, size_t inputSize, unicode_t* target, size_t targetSize, int32_t* errors);
 size_t utf8towide(const char* input, size_t inputSize, wchar_t* target, size_t targetSize, int32_t* errors);
uint8_t utf8isnormalized(const char* input, size_t inputSize, size_t flags, size_t* offset);
 size_t utf8iscategory(const char* input, size_t inputSize, size_t flags);
 size_t utf8normalize(const char* input, size_t inputSize, char* target, size_t targetSize, size_t flags, int32_t* errors);
const char* utf8seek(const char* text, size_t textSize, const char* textStart, off_t offset, int direction);
]]
local lib    = ffi_load     "utf8rewind"
local errors = ffi_new      "int32_t[1]"
local offset = ffi_new       "size_t[1]"
local char_t = ffi_typeof      "char[?]"
local utf16t = ffi_typeof   "utf16_t[?]"
local unicod = ffi_typeof "unicode_t[?]"
local wchart = ffi_typeof   "wchar_t[?]"
local FORM = {
       C = 1,
     NFC = 1,
       D = 2,
     NFD = 2,
      KC = 5,
    NFKC = 5,
      KD = 6,
    NFKD = 6
}
local CATEGORY = {
    LETTER_UPPERCASE        = 1,
    LETTER_LOWERCASE        = 2,
    LETTER_TITLECASE        = 4,
    LETTER_MODIFIER         = 8,
    CASE_MAPPED             = 7,
    LETTER_OTHER            = 16,
    LETTER                  = 31,
    MARK_NON_SPACING        = 32,
    MARK_SPACING            = 64,
    MARK_ENCLOSING          = 128,
    MARK                    = 224,
    NUMBER_DECIMAL          = 256,
    NUMBER_LETTER           = 512,
    NUMBER_OTHER            = 1024,
    NUMBER                  = 1792,
    PUNCTUATION_CONNECTOR   = 2048,
    PUNCTUATION_DASH        = 4096,
    PUNCTUATION_OPEN        = 8192,
    PUNCTUATION_CLOSE       = 16384,
    PUNCTUATION_INITIAL     = 32768,
    PUNCTUATION_FINAL       = 65536,
    PUNCTUATION_OTHER       = 131072,
    PUNCTUATION             = 260096,
    SYMBOL_MATH             = 262144,
    SYMBOL_CURRENCY         = 524288,
    SYMBOL_MODIFIER         = 1048576,
    SYMBOL_OTHER            = 2097152,
    SYMBOL                  = 3932160,
    SEPARATOR_SPACE         = 4194304,
    SEPARATOR_LINE          = 8388608,
    SEPARATOR_PARAGRAPH     = 16777216,
    SEPARATOR               = 29360128,
    CONTROL                 = 33554432,
    FORMAT                  = 67108864,
    SURROGATE               = 134217728,
    PRIVATE_USE             = 268435456,
    UNASSIGNED              = 536870912,
    COMPATIBILITY           = 1073741824,
    ISUPPER                 = 1073741825,
    ISLOWER                 = 1073741826,
    ISALPHA                 = 1073741855,
    ISDIGIT                 = 1073743616,
    ISALNUM                 = 1073743647,
    ISPUNCT                 = 1077934080,
    ISGRAPH                 = 1077935903,
    ISSPACE                 = 1077936128,
    ISPRINT                 = 1107296031,
    ISCNTRL                 = 1107296256,
    ISXDIGIT                = 1342179072,
    ISBLANK                 = 1346371584,
    IGNORE_GRAPHEME_CLUSTER = 2147483648
}
local function process(input, func, target_t, flags, locale)
    local t = target_t or char_t
    local l = type(input) == "cdata" and ffi_sizeof(input) or #input
    local s
    if flags then
        s = lib[func](input, l, nil, 0, flags, errors)
    else
        s = locale and lib[func](input, l, nil, 0, locale, errors) or lib[func](input, l, nil, 0, errors)
    end
    if errors[0] == 0 then
        local target = ffi_new(t, s)
        if flags then
            s = lib[func](input, l, target, s, flags, errors)
        else
            s = locale and lib[func](input, l, target, s, locale, errors) or lib[func](input, l, target, s, errors)
        end
        if errors[0] == 0 then
            if target_t then
                return target, tonumber(s)
            else
                return ffi_str(target, s), tonumber(s)
            end

        end
    end
    return nil, errors[0]
end
local utf8rewind = { maybe = {} }
function utf8rewind.utf8len     (input) return tonumber(lib.utf8len(input))   end
function utf8rewind.utf8toupper (input, locale) return process(input, "utf8toupper",  nil, nil, locale) end
function utf8rewind.utf8tolower (input, locale) return process(input, "utf8tolower",  nil, nil, locale) end
function utf8rewind.utf8totitle (input, locale) return process(input, "utf8totitle",  nil, nil, locale) end
function utf8rewind.utf8casefold(input, locale) return process(input, "utf8casefold", nil, nil, locale) end
function utf8rewind.utf16toutf8 (input) return process(input, "utf16toutf8")  end
function utf8rewind.utf32toutf8 (input) return process(input, "utf32toutf8")  end
function utf8rewind.widetoutf8  (input) return process(input, "widetoutf8")   end
function utf8rewind.utf8toutf16 (input) return process(input, "utf8toutf16", utf16t) end
function utf8rewind.utf8toutf32 (input) return process(input, "utf8toutf32", unicod) end
function utf8rewind.utf8towide  (input) return process(input, "utf8towide",  wchart) end
function utf8rewind.utf8normalize(input, flags)
    flags = flags or FORM.C
    if type(flags) == "string" then
        flags = FORM[flags]
    end
    assert(type(flags) == "number", "Invalid normalization flags supplied.")
    return process(input, "utf8normalize", nil, flags)
end
function utf8rewind.utf8isnormalized(input, flags)
    flags = flags or FORM.C
    if type(flags) == "string" then
        flags = FORM[upper(flags)]
    end
    assert(type(flags) == "number", "Invalid normalization flags supplied.")
    local r = lib.utf8isnormalized(input, #input, flags, offset)
    local n = tonumber(offset[0]) + 1
    if r == 0 then
        return true, true, n
    elseif r == 2 then
        return false, false, n
    else
        return false, true, n
    end
end
function utf8rewind.utf8iscategory(input, flags)
    if type(flags) == "string" then
        flags = CATEGORY[upper(flags)]
    end
    assert(type(flags) == "number", "Invalid category flags supplied.")
    local l = #input
    local r = tonumber(lib.utf8iscategory(input, l, flags))
    if l == r then
        return true
    else
        return false, r + 1
    end
end
function utf8rewind.utf8seek(input, offset, direction)
    return ffi_str(lib.utf8seek(input, #input, input, offset or 0, direction and 2 or 0))
end
function utf8rewind.utf8envlocale()
    return tonumber(lib.utf8envlocale())
end
utf8rewind.form     = FORM
utf8rewind.category = CATEGORY
return utf8rewind