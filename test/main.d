import dconfig;

void main() {}

unittest {

    enum EnumType { Value1, Value2 }

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
            int[string] associativeArray;
            IntAcceptable structVariable;
            EnumType enumVariable;
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
        assert(associativeArray == ["key1" : 1, "key2" : 2]);
        assert(structVariable == 334);
        assert(enumVariable == EnumType.Value1);

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
        assert(associativeArray == ["key1" : 3, "key2" : 4]);
        assert(structVariable == -334);
        assert(enumVariable == EnumType.Value2);
    }

    remove("test.json");
}
