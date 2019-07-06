import std.signals;
import std : JSONValue, isAssociativeArray, isAssignable, isArray, isStaticArray, ForeachType, KeyType, ValueType, JSONType;

class ConfigManager {

    /* Singleton Implementation */
    private static ConfigManager instance;

    public static ConfigManager opCall() {
        if (instance is null) instance = new ConfigManager;
        return instance;
    }

    /* Signal Declaration */
    mixin Signal;
    mixin Signal!(string, string, JSONValue);


    /* Field Declaration */
    private ConfigFile[] files;


    /** load all config files and update config variables */
    void load() {
        emit();
    }

    // return ConfigFile instance using cache if available
    ConfigFile getFile(string path) {
        import std : find, empty, front;

        auto findResult = this.files.find!(file => file.path == path);
        if (!findResult.empty) return findResult.front;

        auto newFile = new ConfigFile(path);
        this.files ~= newFile;

        return newFile;
    }

    // notify config variable update
    private void setValue(string path, string name, JSONValue val) {
        emit(path, name, val);
    }
}


private class ConfigFile {

    /* Signal Declaration */
    mixin Signal!(string, string, JSONValue);

    /* Field Declaration */
    private string path;


    private this(string path) {
        this.path = path;

        // connect instances
        // ConfigManager.emit -> ConfigFile.load -> ConfigManager.load -> ConfigVariable.setValue
        this.connect(&ConfigManager().setValue);
        ConfigManager().connect(&this.load);
    }


    void load() {
        import std : readText, parseJSON;

        auto jsonData = parseJSON(readText(path));
        foreach (string key, value; jsonData) {
            emit(path, key, value);
        }
    }
}

/** converts JSONValue to normal type. (name is necessary only for assertion) */
auto conv(T)(string name, JSONValue value) {
    import std : map, array, format, to;

    static if (isAssociativeArray!T && is(KeyType!T == string)) {
        T result;
        foreach (k, v; value.object()) {
            result[k] = conv!(ValueType!T)(format!`%s["%s"]`(name, k), v);
        }
        return result;
    } else static if (isAssignable!(T, string)) {
        return value.str();
    } else static if (isArray!(T)) {
        static if (isStaticArray!(T)) {
            auto jsonArray = value.array();
            assert(T.length == jsonArray.length,
                    format!"Expected length is '%d', but %s's length is '%d'."(T.length, name, jsonArray.length));
            T result;
            foreach (i, v; jsonArray) {
                result[i] = conv!(ForeachType!(T))(format!"%s[%d]"(name, i), v);
            }
            return result;
        } else {
            return value.array().map!(v => conv!(ForeachType!(T))(name, v)).array;
        }
    } else static if (isAssignable!(T, double)) {
        switch (value.type) {
            case JSONType.integer:  return cast(int)value.integer();
            case JSONType.uinteger: return cast(uint)value.uinteger();
            case JSONType.float_:   return cast(float)value.floating();
            default: break;
        }
    } else static if (isAssignable!(T, int)) {
        switch (value.type) {
            case JSONType.integer:  return cast(int)value.integer();
            case JSONType.uinteger: return cast(uint)value.uinteger();
            default: break;
        }
    } else static if (isAssignable!(T, uint)) {
        switch (value.type) {
            case JSONType.integer:  return cast(int)value.integer();
            case JSONType.uinteger: return cast(uint)value.uinteger();
            default: break;
        }
    } else static if (isAssignable!(T, bool)) {
        switch (value.type) {
            case JSONType.true_:  return true;
            case JSONType.false_: return false;
            default: break;
        }
    } else static if (is(T == enum)) {
        switch (value.type) {
            case JSONType.string: return value.str().to!T;
            default: break;
        }
    } else {
        static assert(false, "Invalid type");
    }

    // This implementation is for avoiding deprecation warning of JSONType.
    final switch (value.type) {
        static foreach (t; [JSONType.null_, JSONType.string, JSONType.integer,
                JSONType.uinteger, JSONType.float_, JSONType.array, JSONType.object, JSONType.true_, JSONType.false_]) {
            case t:
                assert(false, format!"Expected Type is '%s', but %s's type is '%s'."(T.stringof, name, t.stringof));
        }
    }
}

/** UDA for config variable */
static struct config {
    string filePath;
}


mixin template HandleConfig(bool autoCreateConstructor=false) {

    // for a class mixin this, this import is needed.
    import std.json;

    // mostly you don't need constructor.
    static if (autoCreateConstructor) {
        this() {
            this.initializeConfig();
        }
    }

    // activate config variables.
    // after calling this, config variables are assigned and accept reloading.
    void initializeConfig() {
        import std : sort, uniq, getSymbolsByUDA, getUDAs, AliasSeq, replace;

        alias symbols = AliasSeq!(getSymbolsByUDA!(typeof(this), config));
        
        string[] files;
        static foreach (i; 0..symbols.length) {{

            enum SymbolName = symbols[i].stringof.replace("this.", "");
            alias SymbolType = typeof(symbols[i]);
            enum FilePath = getUDAs!(symbols[i], config)[0].filePath;

            // connect ConfigManager.setValue -> ConfigVariable.setValue
            ConfigManager().connect(&__setValue__!(FilePath, SymbolName, SymbolType));

            files ~= FilePath;
        }}

        // first loading
        foreach (filePath; files.sort().uniq()) {
            ConfigManager().getFile(filePath).load();
        }
    }

    private void __setValue__(string __FilePath__, string __SymbolName__, __SymbolType__)(string __path__, string __name__, JSONValue __value__) {
        if (__FilePath__ != __path__) return;
        if (__SymbolName__ != __name__) return;

        mixin(__SymbolName__) = conv!(__SymbolType__)(__name__, __value__);
    }

    void saveConfig() {
        import std : sort ,uniq, to, parseJSON, getSymbolsByUDA, getUDAs, AliasSeq;
        import std.file : write;

        alias symbols = AliasSeq!(getSymbolsByUDA!(typeof(this), config));
        
        JSONValue[string] result;
        static foreach (i; 0..symbols.length) {{
            import std.string : replace;

            enum SymbolName = symbols[i].stringof.replace("this.", "");
            alias SymbolType = typeof(symbols[i]);
            enum FilePath = getUDAs!(symbols[i], config)[0].filePath;


            if (FilePath !in result) result[FilePath] = parseJSON("{}");
            result[FilePath].object[SymbolName] = parseJSON(toJsonString(mixin(SymbolName)));
        }}
        foreach (filePath, content; result) {
            write(filePath, content.toString);
        }
    }

    private string toJsonString(T)(T value) {
        import std : map, join, to, format, isSomeString, isAssociativeArray;

        static if (isAssociativeArray!T) {
            return format!"{
                %s
            }"(value.byKeyValue.map!(t => format!`"%s": %s`(t.key, toJsonString(t.value))).join(",\n"));
        } else static if (isSomeString!T) {
            return value.to!string.format!`"%s"`;
        } else {
            return value.to!string;
        }
    }
}
