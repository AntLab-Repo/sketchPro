
const bit<16> TYPE_IPV4 = 0x800;
const bit<8>  PROTO_TCP = 6;
const bit<8>  PROTO_UDP = 17;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ipv4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;  
    bit<8>      diffserv;  
    bit<16>     totalLen;
    bit<16>     identification; 
    bit<3>      flags; 
    bit<13>     fragOffset;  
    bit<8>      ttl;
    bit<8>      protocol; 
    bit<16>     hdrChecksum;
    ipv4Addr_t  srcAddr;
    ipv4Addr_t  dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

struct metadata {
    bit<104>    flowId; 
    bit<64>     sketchEntry;
    bit<54>     arrayEntry; 
    bit<32>     bucketIndex;
    bit<32>     currentKey;   
    bit<22>     currentCount;
    bit<10>      currentCollision;
    bit<32>     carriedKey;
    bit<22>     carriedCount;
    bit<10>      carriedCollision;
    bit<32>     toWriteKey;
    bit<22>     toWriteCount;
    bit<10>      toWriteCollision;
    bit<12>     random_bit_shorts;
    bit<22>     difference; 
}

struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
    tcp_t       tcp;
    udp_t       udp; 
}
