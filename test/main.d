import dconfig;

void main() {}

unittest {

    class Config {

        mixin HandleConfig;

        private struct IntAcceptable {int x; alias x this; }

        @config("test.json") {
            int intVariable;
            uint uintVariable;
            float floatVariable;
            bool boolVariable;
            string stringVariable;
            int[3] intStaticArray;
            int[] intDynamicArray;
            int[3][2] multiArray;
            IntAcceptable structVariable;
        }

        this() {
            this.initializeConfig();
        }
    }

    import std.file : copy, remove;

    copy("test1.json", "test.json");

    with (new Config()) {

        import std.math : approxEqual;

        assert(intVariable == 114514);
        assert(uintVariable == 114514);
        assert(approxEqual(floatVariable, 8.10, float.epsilon));
        assert(boolVariable == true);
        assert(stringVariable == "testString");
        assert(intStaticArray == [3, 3, 4]);
        assert(intDynamicArray == [3, 3, 4]);
        assert(multiArray == [[1,2,3], [4,5,6]]);
        assert(structVariable == 334);

        copy("test2.json", "test.json");
        ConfigManager().load();

        assert(intVariable == -114514);
        assert(uintVariable == 0);
        assert(approxEqual(floatVariable, -8.10, float.epsilon));
        assert(boolVariable == false);
        assert(stringVariable == "testString2");
        assert(intStaticArray == [-3, 3, 4]);
        assert(intDynamicArray == [-3, 3, 4]);
        assert(multiArray == [[4,5,6], [1,2,3]]);
        assert(structVariable == -334);
    }

    remove("test.json");

    with(new Config) {
        import std.math : isNaN;
        assert(intVariable == 0);
        assert(uintVariable == 0);
        assert(floatVariable.isNaN);
        assert(boolVariable == false);
        assert(stringVariable == "");
        assert(intStaticArray == [0,0,0]);
        assert(intDynamicArray == []);
        assert(multiArray == [[0,0,0], [0,0,0]]);
        assert(structVariable == 0);

        intVariable = 1;
        uintVariable = 1;
        floatVariable = 4;
        boolVariable = true;
        stringVariable = "514";
        intStaticArray = [8,1,0];
        intDynamicArray = [9,3,1];
        multiArray = [[1,1,4], [5,1,4]];
        structVariable = 1_000_000_007;

        saveConfig();
    }

    with(new Config) {
        import std.math : isNaN, approxEqual;
        assert(intVariable == 1);
        assert(uintVariable == 1);
        assert(approxEqual(floatVariable, 4, float.epsilon));
        assert(boolVariable == true);
        assert(stringVariable == "514");
        assert(intStaticArray == [8,1,0]);
        assert(intDynamicArray == [9,3,1]);
        assert(multiArray == [[1,1,4], [5,1,4]]);
        assert(structVariable == 1_000_000_007);
    }

    remove("test.json");
}
