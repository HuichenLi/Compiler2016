package Compiler;

import Compiler.AST.Parser.MagLexer;
import Compiler.AST.Parser.MagParser;
import Compiler.Environment.SymbolTable;
import Compiler.Error.CompileError;
import Compiler.Listener.ClassDeclListener;
import Compiler.Listener.FunctionDeclListener;
import Compiler.Listener.MagASTBuilder;
import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.ParseTreeWalker;

import java.io.FileInputStream;
import java.io.InputStream;

public class Main {
    public static void main(String[] args) {
        try {
            new Main().compile(args);
        } catch (Exception e) {
            e.printStackTrace();
        } catch (CompileError e) {
            System.out.println(e.getMessage());
            System.exit(1);
        }
    }

    public void compile(String[] args) throws Exception {
        SymbolTable.initilize();

        ANTLRInputStream input = new ANTLRInputStream(System.in);
        //ANTLRInputStream input = new ANTLRInputStream(System.in);
        MagLexer lexer = new MagLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        MagParser parser = new MagParser(tokens);
        ParseTree tree = parser.program(); // calc is the starting rule

        System.out.println("LISP:");
        System.out.println(tree.toStringTree(parser));
        System.out.println();

        ParseTreeWalker walker = new ParseTreeWalker();
        walker.walk(new ClassDeclListener(), tree);
        walker.walk(new FunctionDeclListener(), tree);
        walker.walk(new MagASTBuilder(), tree);

        System.out.println("Listener:");

        /*AST root = evalByListener.stack.peek();
        Printer printer = new Printer();
        printer.visit(root);*/
        System.out.println(MagASTBuilder.stack.peek().toString(0));
    }
}
