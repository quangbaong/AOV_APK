using System;
using System.Linq;
using Mono.Cecil;
using Mono.Cecil.Cil;

class PatchDefaultFallback
{
    static void Main(string[] args)
    {
        var assembly = AssemblyDefinition.ReadAssembly(args[0]);
        var module = assembly.MainModule;
        var type = module.Types.Single(t => t.Name == "Il2CppExecutor");
        var method = type.Methods.Single(m => m.Name == "TryGetDefaultValue");
        var body = method.Body;
        if (body.ExceptionHandlers.Count != 0) throw new Exception("Unexpected exception handlers");
        var metadata = body.Instructions.Select(i => i.Operand).OfType<FieldReference>().First(f => f.Name == "metadata");
        var getOffset = body.Instructions.Select(i => i.Operand).OfType<MethodReference>().First(m => m.Name == "GetDefaultValueFromIndex");
        var count = new FieldDefinition("UnresolvedDefaultReads", FieldAttributes.Public | FieldAttributes.Static, module.TypeSystem.Int32);
        type.Fields.Add(count);
        var result = new VariableDefinition(module.TypeSystem.Boolean);
        body.Variables.Add(result);
        body.InitLocals = true;
        var il = body.GetILProcessor();
        var first = body.Instructions[0];
        var epilogue = Instruction.Create(OpCodes.Ldloc, result);
        foreach (var ret in body.Instructions.Where(i => i.OpCode == OpCodes.Ret).ToArray())
        {
            ret.OpCode = OpCodes.Stloc;
            ret.Operand = result;
            il.InsertAfter(ret, Instruction.Create(OpCodes.Leave, epilogue));
        }
        var handler = Instruction.Create(OpCodes.Pop);
        il.Append(handler);
        il.Append(Instruction.Create(OpCodes.Ldsfld, count));
        il.Append(Instruction.Create(OpCodes.Ldc_I4_1));
        il.Append(Instruction.Create(OpCodes.Add));
        il.Append(Instruction.Create(OpCodes.Stsfld, count));
        il.Append(Instruction.Create(OpCodes.Ldarg_3));
        il.Append(Instruction.Create(OpCodes.Ldarg_0));
        il.Append(Instruction.Create(OpCodes.Ldfld, metadata));
        il.Append(Instruction.Create(OpCodes.Ldarg_2));
        il.Append(Instruction.Create(OpCodes.Callvirt, getOffset));
        il.Append(Instruction.Create(OpCodes.Box, module.TypeSystem.UInt32));
        il.Append(Instruction.Create(OpCodes.Stind_Ref));
        il.Append(Instruction.Create(OpCodes.Ldc_I4_0));
        il.Append(Instruction.Create(OpCodes.Stloc, result));
        il.Append(Instruction.Create(OpCodes.Leave, epilogue));
        il.Append(epilogue);
        il.Append(Instruction.Create(OpCodes.Ret));
        body.ExceptionHandlers.Add(new ExceptionHandler(ExceptionHandlerType.Catch) {
            CatchType = module.ImportReference(typeof(Exception)),
            TryStart = first, TryEnd = handler, HandlerStart = handler, HandlerEnd = epilogue
        });
        body.MaxStackSize = Math.Max(body.MaxStackSize, 5);
        var main = module.EntryPoint;
        var mainIl = main.Body.GetILProcessor();
        var writeLine = module.ImportReference(typeof(Console).GetMethod("WriteLine", new Type[] {typeof(string), typeof(object)}));
        foreach(var ret in main.Body.Instructions.Where(i => i.OpCode == OpCodes.Ret).ToArray()) {
            mainIl.InsertBefore(ret, Instruction.Create(OpCodes.Ldstr, "Unresolved default reads retained as metadata offsets: {0}"));
            mainIl.InsertBefore(ret, Instruction.Create(OpCodes.Ldsfld, count));
            mainIl.InsertBefore(ret, Instruction.Create(OpCodes.Box, module.TypeSystem.Int32));
            mainIl.InsertBefore(ret, Instruction.Create(OpCodes.Call, writeLine));
        }
        assembly.Write(args[1]);
        Console.WriteLine("Patched fallback; source metadata unchanged.");
    }
}
