# dconfig

## what is dconfig?
dconfig is a library for D programming language.
This library can easily manage D's variables and values writteln in JSON.

## usage
Add dependency for dconfig to your `dub.sdl`(`dub.json)`

### example
```d
void main() {
    import dconfig;
    
    // prepare config class
    class Test {
        mixin HandleConfig;
        this() { this.initializeConfig(); }

        @config("test.json") int x;
    }
    
    // class instance is auto assigned JSON value
    import std.file : write;
    write("test.json", `{"x": 334}`);
    auto test = new Test;
    assert(test.x == 334);
    
    // you can reload while running
    write("test.json", `{"x": 810}`);
    ConfigManager().load();
    assert(test.x == 810);
}
