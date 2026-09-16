local nfd_bind = {}

local ffi = require 'ffi'

ffi.cdef [[
typedef char nfdu8char_t;
typedef unsigned int nfdfiltersize_t;

typedef enum {
    NFD_ERROR,
    NFD_OKAY,
    NFD_CANCEL
} nfdresult_t;

typedef struct {
    const nfdu8char_t* name;
    const nfdu8char_t* spec;
} nfdu8filteritem_t;


void NFD_FreePathU8(nfdu8char_t* filePath);
nfdresult_t NFD_Init(void);
void NFD_Quit(void);
nfdresult_t NFD_OpenDialogU8(nfdu8char_t** outPath,
                             const nfdu8filteritem_t* filterList,
                             nfdfiltersize_t filterCount,
                             const nfdu8char_t* defaultPath);
nfdresult_t NFD_SaveDialogU8(nfdu8char_t** outPath,
                             const nfdu8filteritem_t* filterList,
                             nfdfiltersize_t filterCount,
                             const nfdu8char_t* defaultPath,
                             const nfdu8char_t* defaultName);
const char* NFD_GetError(void);
]]

local nfd = ffi.load('nfd')

local function nfd_init()
  local result = nfd.NFD_Init()
  if result ~= nfd.NFD_OKAY then
    nfd.NFD_Quit()
    error(ffi.string(nfd.NFD_GetError()))
  end
end

local function nfd_finalize(result, outPath)
  nfd.NFD_Quit()
  if result == nfd.NFD_ERROR then
    error(ffi.string(nfd.NFD_GetError()))
  elseif result == nfd.NFD_CANCEL then
    return
  else
    local output = ffi.string(outPath[0])
    nfd.NFD_FreePathU8(outPath[0])
    return output
  end
end

function nfd_bind.open(filters, path)
  nfd_init()

  filters = filters or {}

  local outPath = ffi.new('char*[1]')
  local filterList = ffi.new('nfdu8filteritem_t[?]', #filters)

  local tmp = {}
  for i, filter in ipairs(filters) do
    tmp[i - 1] = ffi.new('nfdu8filteritem_t', filter)
    filterList[i - 1] = tmp[i - 1]
  end

  return nfd_finalize(nfd.NFD_OpenDialogU8(outPath, filterList, #filters, path), outPath)
end

function nfd_bind.save(filters, path, name)
  nfd_init()

  filters = filters or {}

  local outPath = ffi.new('char*[1]')
  local filterList = ffi.new('nfdu8filteritem_t[?]', #filters)

  local tmp = {}
  for i, filter in ipairs(filters) do
    tmp[i - 1] = ffi.new('nfdu8filteritem_t', filter)
    filterList[i - 1] = tmp[i - 1]
  end

  return nfd_finalize(nfd.NFD_SaveDialogU8(outPath, filterList, #filters, path, name), outPath)
end

return nfd_bind