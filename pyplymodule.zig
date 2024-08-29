const py = @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
});

const std = @import("std");

const pyply = @import("src/lib/zig-ply/src/parser.zig");

const PyArg_ParseTuple = py.PyArg_ParseTuple;
const PyObject = py.PyObject;
const PyDict_New = py.PyDict_New;
const PyMethodDef = py.PyMethodDef;
const PyModuleDef = py.PyModuleDef;
const PyModuleDef_Base = py.PyModuleDef_Base;
const PyModule_Create = py.PyModule_Create;
const PyDict_SetItem = py.PyDict_SetItem;
const PyList_SetItem = py.PyList_SetItem;
const Py_BuildValue = py.Py_BuildValue;
const METH_VARARGS = py.METH_VARARGS;
const PyFloat_FromDouble = py.PyFloat_FromDouble;
const PyLong_FromUnsignedLong = py.PyLong_FromUnsignedLong;
const PyList_New = py.PyList_New;
const PyTuple_New = py.PyTuple_New;
const PyTuple_SetItem = py.PyTuple_SetItem;


fn load_ply(self: [*c]PyObject, args: [*c]PyObject) callconv(.C) [*]PyObject {
    _ = self;

    var string: [*:0]const u8 = undefined;

    _ = PyArg_ParseTuple(args, "s", &string);

    var fsm = pyply.FiniteStateMachine.init();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const mesh = fsm.parseAlloc(alloc, std.mem.sliceTo(string, 0)) catch unreachable;
    

    const vertex_list = PyList_New(@intCast(fsm.num_v));
    const faces_list = PyList_New(@intCast(fsm.num_f));

    for (mesh.vertices, 0..) |v, i| {
        const vertex = PyList_New(3);
        for (0..3) |j| {
            const j_i: isize = @intCast(j);
            const vertex_as_double: f64 = @floatCast(v[j]);
            const py_float = PyFloat_FromDouble(vertex_as_double);
            _ = PyList_SetItem(vertex, j_i, py_float);
        }
        const i_i: isize = @intCast(i);
        _ = PyList_SetItem(vertex_list, i_i, vertex);
    }

    for (mesh.faces, 0..) |f, i| {
        const face = PyList_New(3);
        for (0..3) |j| {
            const j_i: isize = @intCast(j);
            const face_as_long: u64 = @intCast(f[j]);
            const py_long = PyLong_FromUnsignedLong(face_as_long);
            _ = PyList_SetItem(face, j_i, py_long);
        }
        const i_i: isize = @intCast(i);
        _ = PyList_SetItem(faces_list, i_i, face);
    }

    const ret_tuple = PyTuple_New(2);
    _ = PyTuple_SetItem(ret_tuple, 0, vertex_list);
    _ = PyTuple_SetItem(ret_tuple, 1, faces_list);
    return ret_tuple;
}

var PyPlyMethods = [_]PyMethodDef{
    PyMethodDef{
        .ml_name = "load",
        .ml_meth = load_ply,
        .ml_flags = METH_VARARGS,
        .ml_doc = "Load .ply file.",
    },
    PyMethodDef{
        .ml_name = null,
        .ml_meth = null,
        .ml_flags = 0,
        .ml_doc = null,
    },
};

var pyplymodule = PyModuleDef{
    .m_base = PyModuleDef_Base{
        .ob_base = PyObject{
            .ob_refcnt = 1,
            .ob_type = null,
        },
        .m_init = null,
        .m_index = 0,
        .m_copy = null,
    },
    .m_name = "pyply",
    .m_doc = null,
    .m_size = -1,
    .m_methods = &PyPlyMethods,
    .m_slots = null,
    .m_traverse = null,
    .m_clear = null,
    .m_free = null,
};

pub export fn PyInit_pyply() [*]PyObject {
    return PyModule_Create(&pyplymodule);
}
