fennel = require("fennel").install({correlate=true,
                                    moduleName="assets.fennel"})

package.loaded.fennel = fennel

pp = function (text)
   print (fennel.view (text))
   io.flush()
end

require("wrap")
