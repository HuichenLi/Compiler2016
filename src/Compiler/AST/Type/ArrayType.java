package Compiler.AST.Type;

import Compiler.AST.Decl.FunctionDecl;
import Compiler.AST.Decl.VarDecl;
import Compiler.AST.Statement.Expression.BinaryOp;
import Compiler.AST.Statement.Expression.Expression;
import Compiler.AST.Symbol;
import Compiler.AST.VarDeclList;
import Compiler.ControlFlowGraph.Instruction.BinaryInstruction;
import Compiler.ControlFlowGraph.Instruction.Instruction;
import Compiler.Error.CompileError;
import Compiler.Operand.Immediate;
import Compiler.Operand.Operand;
import Compiler.Operand.Register;

import java.util.HashMap;
import java.util.List;

import static Compiler.Tool.Tool.indent;

/**
 * Created by Alri on 16/3/31.
 */
public class ArrayType implements Type {
    private static HashMap<Symbol, Type> members;
    public Type baseType;
    public Expression arraySize;

    public ArrayType(Type bt) {
        baseType = bt;
        arraySize = null;
    }

    public ArrayType(Type bt, Expression as) {
        baseType = bt;
        arraySize = as;
    }

    public static void initialize() {
        members = new HashMap<>();
        Symbol thisSymbol = Symbol.getSymbol("this");
        VarDeclList varDeclList = new VarDeclList(new VarDecl(new StringType(), thisSymbol));

        // int pointerSize()
        Symbol sizeSymbol = Symbol.getSymbol("pointerSize");
        members.put(sizeSymbol, new FunctionDecl(
                new IntType(),
                sizeSymbol,
                varDeclList,
                null
            )
        );
    }

    public void changeSize(Expression as) {
        arraySize = as;
    }

    @Override
    public Type getMemberType(Symbol memberSymbol) {
        if (members.containsKey(memberSymbol)) {
            return members.get(memberSymbol);
        }
        throw new CompileError("no member");
    }

    @Override
    public String toString(int d) {
        String string = indent(d) + "ArrayType\n";
        if (baseType != null) string += baseType.toString(d + 1);
        if (arraySize != null) string += arraySize.toString(d + 1);
        return string;
    }

    @Override
    public boolean equal(Type rhs) {
        if (rhs instanceof ArrayType)
            return baseType.equal(((ArrayType) rhs).baseType);
        else
            return false;
    }

    @Override
    public long pointerSize() {
        return 4;
    }

    @Override
    public Operand alloc(List<Instruction> instructions) {
        Operand reg = new Register();
        instructions.add(new BinaryInstruction(BinaryOp.MUL, (Register) reg, arraySize.operand, new Immediate(baseType.pointerSize())));
        return reg;
    }
}
