try:
    from CParser cimport *
except:
    try:
        from CompiledFiles.CParser cimport *
    except:
        from Task.CompiledFiles.CParser cimport *


def main(str name, path):
    cdef str if_text = ""
    cdef str for_text = ""
    cdef str func_text = ""
    cdef symbol_table = SymbolTable()
    cdef local_table = LocalSymbolTable()
    cdef func_table = FuncTable()
    cdef libs = []
    cdef libs_name = []
    cdef file = open(path, "r", encoding="utf-8")
    while True:
        try:
            text = file.readline()
            text = rewrite_code(file, text, libs_name, libs, if_text, for_text, func_text, path)
        except EOFError:
            break

        if not text:
            break

        if "<module>" in text:
            text = text.replace("<module>", "")

        lexer = Lexer(text)
        parser = Parser(lexer, symbol_table, local_table, func_table, libs_name, libs)
        parser.parse()