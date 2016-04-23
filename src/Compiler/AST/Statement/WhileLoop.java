package Compiler.AST.Statement;

import Compiler.AST.Statement.Expression.Expression;
import Compiler.AST.Type.BoolType;
import Compiler.ControlFlowGraph.Instruction.ConditionBranchInstruction;
import Compiler.ControlFlowGraph.Instruction.Instruction;
import Compiler.ControlFlowGraph.Instruction.JumpInstruction;
import Compiler.ControlFlowGraph.Instruction.LabelInstruction;
import Compiler.Error.CompileError;

import java.util.List;

import static Compiler.Tool.Tool.indent;

/**
 * Created by Alri on 16/3/31.
 */
public class WhileLoop implements Statement {
    public Expression condition;
    public Statement body;

    public WhileLoop(Expression cond, Statement b) {
        if (!(cond.type instanceof BoolType)) {
            throw new CompileError("A BoolType expression is expected in WhileLoop.");
        }
        condition = cond;
        body = b;
    }

    @Override
    public String toString(int d) {
        String string = indent(d) + "WhileLoop\n";
        string += condition.toString(d + 1);
        string += body.toString(d + 1);
        return string;
    }

    @Override
    public void emit(List<Instruction> instruction) {
        LabelInstruction whileLoopLabel = new LabelInstruction("WhileLoop");
        LabelInstruction bodyLabel = new LabelInstruction("WhileBody");
        LabelInstruction outLabel = new LabelInstruction("OutOfWhile");
        instruction.add(whileLoopLabel);
        condition.emit(instruction);
        instruction.add(new ConditionBranchInstruction(condition.register, bodyLabel, outLabel));
        instruction.add(bodyLabel);
        body.emit(instruction);
        instruction.add(new JumpInstruction(whileLoopLabel));
        instruction.add(outLabel);
    }
}
