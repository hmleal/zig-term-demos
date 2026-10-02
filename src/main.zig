const std = @import("std");
const Io = std.Io;

const term = @import("term");

pub const drop = struct {
    x: u16,
    y: u16,
    speed: u16,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // const arena: std.mem.Allocator = init.arena.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    const stdin = std.Io.File.stdin();

    const size = try term.getSize(stdin);
    const state = try term.makeRaw(stdin);
    defer term.restore(stdin, state) catch {};

    const source: std.Random.IoSource = .{ .io = io };
    const random = source.interface();

    const drops = try init.arena.allocator().alloc(drop, size.width);
    for (drops, 0..) |*d, x| {
        d.* = .{ .x = @intCast(x), .y = 1, .speed = random.intRangeAtMost(u16, 0, size.height) };
    }

    var running = std.atomic.Value(bool).init(true);

    const thread = try std.Thread.spawn(.{}, readInput, .{
        io,
        stdin,
        &running,
    });
    defer thread.join();

    while (running.load(.acquire)) {
        for (drops) |*d| {
            d.y += d.speed;

            if (d.y >= size.height) {
                d.y = 0;
                d.speed = 1;
            }
            const rand_int = random.intRangeAtMost(u16, 0, 35);
            const char = [36]u8{
                'A', 'B', 'C', 'D',
                'E', 'F', 'G', 'H',
                'I', 'J', 'K', 'L',
                'M', 'N', 'O', 'P',
                'Q', 'R', 'S', 'T',
                'U', 'V', 'W', 'X',
                'Y', 'Z', '0', '1',
                '2', '3', '4', '5',
                '6', '7', '8', '9',
            };

            try stdout_writer.print("\x1b[{d};{d}H\x1b[32m{s}", .{ d.y + 1, d.x + 1, char[rand_int .. rand_int + 1] });
        }

        try std.Io.sleep(io, .fromMilliseconds(50), .awake);
        try stdout_writer.flush();
    }
    // Reset terminal.
    try stdout_writer.writeAll("\x1b[0m\x1b[?25h\n");
    try stdout_writer.flush();
}

fn readInput(io: std.Io, stdin: std.Io.File, running: *std.atomic.Value(bool)) void {
    var read_buffer: [1]u8 = undefined;
    var stdin_file_reader: Io.File.Reader = .init(stdin, io, &read_buffer);

    while (running.load(.acquire)) {
        const byte = stdin_file_reader.interface.takeByte() catch return;

        if (byte == 3 or byte == 'q') {
            running.store(false, .release);
            return;
        }
    }
}

// pub fn main(init: std.process.Init) !void {
//     // In order to do I/O operations need an `Io` instance.
//     const io = init.io;
//
//     // This is appropriate for anything that lives as long as the process.
//     // const arena: std.mem.Allocator = init.arena.allocator();
//
//     var stdout_buffer: [1024]u8 = undefined;
//     var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
//     const stdout_writer = &stdout_file_writer.interface;
//
//     const stdin = std.Io.File.stdin();
//     const size = try term.getSize(stdin);
//     const state = try term.makeRaw(stdin);
//     defer term.restore(stdin, state) catch {};
//
//     try stdout_writer.print("\x1b[H", .{});
//     try stdout_writer.print("\x1b[2J", .{});
//
//     // width  64
//     // heigth 32
//
//     for (0..size.height) |i| {
//         // First Line
//         if (i == 0) {
//             for (0..size.width) |j| {
//                 if (j == 0) {
//                     try stdout_writer.print("\x1b[{d};0H", .{size.height});
//                     try stdout_writer.print("screenRows: {d} screenCols: {d}", .{ size.height, size.width });
//                     continue;
//                 }
//                 if (j + 1 == size.width) {
//                     try stdout_writer.print("╮\n", .{});
//                     continue;
//                 }
//                 try stdout_writer.print("─", .{});
//             }
//             continue; // next line
//         }
//     }
//
//     try stdout_writer.print("\x1b[{d};0H", .{size.height - 1});
//     try stdout_writer.print("screenRows: {d} screenCols: {d}", .{ size.height, size.width });
//
//     // try stdout_writer.print("\nterm.isTerminal: {}\n", .{try term.isTerminal(io, stdin)});
//     // try stdout_writer.print("term.getSize: Width: {d}, Height: {d}\n", .{ size.width, size.height });
//     try stdout_writer.flush(); // Don't forget to flush!
// }
