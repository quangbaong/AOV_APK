using System;
using System.Runtime.InteropServices;

namespace Il2CppDumper
{
    public static class MetadataDeobfuscator
    {
        private const uint ObfuscatedMagic = 0xEAB11BAF;
        private const uint ExpectedVersion = 29;
        private const int HeaderLength = 0x100;

        public static bool IsObfuscatedMagic(uint magic) => magic == ObfuscatedMagic;

        public static bool TryDeobfuscateV29Header(byte[] data)
        {
            if (data == null || data.Length < HeaderLength)
            {
                return false;
            }

            var sanity = BitConverter.ToUInt32(data, 0);
            if (sanity != ObfuscatedMagic)
            {
                return false;
            }

            var version = BitConverter.ToUInt32(data, 4);
            if (version != ExpectedVersion)
            {
                return false;
            }

            var headerSpan = MemoryMarshal.Cast<byte, uint>(data.AsSpan(0, HeaderLength));
            var input = headerSpan.ToArray();
            var output = new uint[64];

            output[0] = input[0];
            output[1] = input[1];
            for (var i = 50; i < 64; i++)
            {
                output[i] = input[i];
            }

            output[4] = input[2] ^ 0x00A8C72D;
            output[5] = input[3] ^ 0x00A8C72D;
            output[8] = XorSubtract(input[4], 3, 0x00A8C72E);
            output[9] = XorSubtract(input[5], 7, 0x00A8C72F);
            output[12] = XorSubtract(input[6], 6, 0x00A8C72F);
            output[13] = XorSubtract(input[7], 14, 0x00A8C731);
            output[16] = XorSubtract(input[8], 9, 0x00A8C730);
            output[17] = XorSubtract(input[9], 21, 0x00A8C733);
            output[20] = XorSubtract(input[10], 12, 0x00A8C731);
            output[21] = XorSubtract(input[11], 28, 0x00A8C735);
            output[6] = XorSubtract(input[12], 15, 0x00A8C732);
            output[7] = XorSubtract(input[13], 35, 0x00A8C737);
            output[10] = XorSubtract(input[14], 18, 0x00A8C733);
            output[11] = XorSubtract(input[15], 42, 0x00A8C739);
            output[14] = XorSubtract(input[16], 21, 0x00A8C734);
            output[15] = XorSubtract(input[17], 49, 0x00A8C73B);
            output[18] = XorSubtract(input[18], 24, 0x00A8C735);
            output[19] = XorSubtract(input[19], 56, 0x00A8C73D);
            output[22] = XorSubtract(input[20], 27, 0x00A8C736);
            output[23] = XorSubtract(input[21], 63, 0x00A8C73F);
            output[2] = XorSubtract(input[22], 30, 0x00A8C737);
            output[3] = XorSubtract(input[23], 70, 0x00A8C741);
            output[48] = XorSubtract(input[24], 33, 0x00A8C738);
            output[49] = XorSubtract(input[25], 77, 0x00A8C743);
            output[46] = XorSubtract(input[26], 36, 0x00A8C739);
            output[47] = XorSubtract(input[27], 84, 0x00A8C745);
            output[44] = XorSubtract(input[28], 39, 0x00A8C73A);
            output[45] = XorSubtract(input[29], 91, 0x00A8C747);
            output[42] = XorSubtract(input[30], 42, 0x00A8C73B);
            output[43] = XorSubtract(input[31], 98, 0x00A8C749);
            output[24] = XorSubtract(input[32], 45, 0x00A8C73C);
            output[25] = XorSubtract(input[33], 105, 0x00A8C74B);
            output[28] = XorSubtract(input[34], 48, 0x00A8C73D);
            output[29] = XorSubtract(input[35], 112, 0x00A8C74D);
            output[32] = XorSubtract(input[36], 51, 0x00A8C73E);
            output[33] = XorSubtract(input[37], 119, 0x00A8C74F);
            output[36] = XorSubtract(input[38], 54, 0x00A8C73F);
            output[37] = XorSubtract(input[39], 126, 0x00A8C751);
            output[40] = XorSubtract(input[40], 57, 0x00A8C740);
            output[41] = XorSubtract(input[41], 133, 0x00A8C753);
            output[26] = XorSubtract(input[42], 60, 0x00A8C741);
            output[27] = XorSubtract(input[43], 140, 0x00A8C755);
            output[30] = XorSubtract(input[44], 63, 0x00A8C742);
            output[31] = XorSubtract(input[45], 147, 0x00A8C757);
            output[34] = XorSubtract(input[46], 66, 0x00A8C743);
            output[35] = XorSubtract(input[47], 154, 0x00A8C759);
            output[38] = XorSubtract(input[48], 69, 0x00A8C744);
            output[39] = XorSubtract(input[49], 161, 0x00A8C75B);

            for (var i = 0; i < output.Length; i++)
            {
                headerSpan[i] = output[i];
            }

            headerSpan[0] = 0xFAB11BAF;
            return true;
        }

        public static bool DeobfuscateMetadata(byte[] data)
        {
            return TryDeobfuscateV29Header(data);
        }

        private static uint XorSubtract(uint value, uint sub, uint key)
        {
            return (((value - sub) & 0xFFFFFFFF) ^ key) & 0xFFFFFFFF;
        }
    }
}
