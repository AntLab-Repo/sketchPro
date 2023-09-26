#include <core.p4>
#include <v1model.p4>

#include "includes/headers.p4"
#include "includes/parsers.p4"


#define SketchColumn 400   
#define ArrayColumn 200    
#define BUCKET_WIDTH 60  
#define arrayBucket_width 52


#define Init_Sketch_Register(num) register<bit<BUCKET_WIDTH>>(SketchColumn) register_stage##num
#define Init_Array_Register(num) register<bit<arrayBucket_width>>(ArrayColumn) register_array##num
#define HASH_key(num) hash(meta.carriedKey,HashAlgorithm.crc32,32w0,{meta.flowId},32w0-1)
#define HASH_Index(num,seed) hash(meta.bucketIndex,HashAlgorithm.crc32,(bit<32>)0,{meta.carriedKey,seed},(bit<32>)SketchColumn)				
#define HASH_Array_Index(num,seed) hash(meta.bucketIndex,HashAlgorithm.crc32,(bit<32>)0,{meta.carriedKey,seed},(bit<32>)ArrayColumn)
#define Read_Sketch_Register(num) register_stage##num.read(meta.sketchEntry, meta.bucketIndex)
#define Read_Array_Register(num) register_array##num.read(meta.arrayEntry, meta.bucketIndex)
#define Write_Register(num,sketchEntry) register_stage##num.write(meta.bucketIndex, sketchEntry)
#define Write_Array_Register(num,arrayEntry) register_array##num.write(meta.bucketIndex, arrayEntry)


#define STAGE_Array(num,seed) { \
    if(meta.carriedKey != 0){ \
        bit<52> temp; \
        HASH_Array_Index(num,seed);\
        Read_Array_Register(num);\
        meta.currentKey = meta.arrayEntry[51:20]; \
        meta.currentCount = meta.arrayEntry[19:0]; \
        if(meta.currentCount == 0 || meta.currentKey == meta.carriedKey){\
    	    meta.toWriteKey = meta.carriedKey;\
    	    meta.toWriteCount = meta.currentCount + meta.carriedCount;\
    	    meta.carriedKey=0;\
    	    meta.carriedCount=0;\
    	    temp = meta.toWriteKey ++ meta.toWriteCount; \
            Write_Array_Register(num, temp); \
    	}\
        else if(meta.carriedCount > meta.currentCount){\
            meta.toWriteKey = meta.carriedKey;\
            meta.toWriteCount = meta.carriedCount;\
            meta.carriedKey = meta.currentKey;\
            meta.carriedCount = meta.currentCount;\
            temp = meta.toWriteKey ++ meta.toWriteCount;\
            Write_Array_Register(num,temp);\
        }\
    } \
}\


control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {

    Init_Sketch_Register(0);   //Chief
    Init_Array_Register(1);    //Auxiliary slice1
    Init_Array_Register(2);    //Auxiliary slice2
    Init_Array_Register(3);    //Auxiliary slice3
    Init_Array_Register(4);    //Auxiliary slice4

 
    action drop() { mark_to_drop(standard_metadata); }
    action forward_spec(){ standard_metadata.egress_spec = 2; }

    action get_flowKey(){
        meta.flowId[103:72] = hdr.ipv4.srcAddr; 
        meta.flowId[71:40] = hdr.ipv4.dstAddr;  
        meta.flowId[39:32] = hdr.ipv4.protocol;
        
        if(hdr.tcp.isValid()) { 
            meta.flowId[31:16] = hdr.tcp.srcPort;  
            meta.flowId[15:0] = hdr.tcp.dstPort; } 
        else if(hdr.udp.isValid()) { 
            meta.flowId[31:16] = hdr.udp.srcPort;  
            meta.flowId[15:0] = hdr.udp.dstPort; }
        else {
            meta.flowId[31:16] = 0;
            meta.flowId[15:0] = 0;
        }
        HASH_key(meta.flowId);   
    }
    
    
    action replace_action0(){
        bit<60> temp;
        meta.toWriteKey = meta.carriedKey;
        meta.toWriteCount = 1;
        meta.toWriteCollision = 0;
        meta.carriedKey = meta.currentKey;
        meta.carriedCount = meta.currentCount;
        meta.carriedCollision = 0;
        temp = meta.toWriteKey ++ meta.toWriteCount ++meta.toWriteCollision;
        Write_Register(0,temp);
        
    }

    table replace0 {
        key = {
            meta.difference : ternary;
            meta.random_bit_shorts : range;
        }
        actions = {
            replace_action0;
            drop;
        }
        default_action = drop();
        const entries = {
            #include "table_match.p4"  // probability calculation
        }
    }


    apply { 
        get_flowKey();
        meta.carriedCount = 1;
        meta.carriedCollision = 0;
        bit<60> temp1;
        HASH_Index(0, 104w00000000000000000000); 
        Read_Sketch_Register(0); 
        meta.currentKey = meta.sketchEntry[59:28];
        meta.currentCount = meta.sketchEntry[27:8];
        meta.currentCollision = meta.sketchEntry[7:0];

        if (meta.currentKey == 0) { 
            meta.toWriteKey = meta.carriedKey;
            meta.toWriteCount = 1;
            meta.toWriteCollision = 0;
            meta.carriedKey = 0;
            meta.carriedCount = 0;
            meta.carriedCollision = 0;
            temp1 = meta.toWriteKey ++ meta.toWriteCount ++ meta.toWriteCollision;
            Write_Register(0,temp1);
        }
        else if (meta.currentKey == meta.carriedKey) { 
            meta.toWriteKey = meta.currentKey;
            meta.toWriteCount = meta.currentCount + meta.carriedCount; 
            meta.toWriteCollision = meta.currentCollision; 
            meta.carriedKey = 0;
            meta.carriedCount = 0;
            meta.carriedCollision = 0;
            temp1 = meta.toWriteKey ++ meta.toWriteCount ++ meta.toWriteCollision;
            Write_Register(0,temp1);
        }
        else{ 
            meta.currentCollision = meta.currentCollision |+| 1;
            temp1 = meta.currentKey ++ meta.currentCount ++ meta.currentCollision; 
            Write_Register(0,temp1);  
            random<bit<12>>(meta.random_bit_shorts,12w0,12w0-1);\
            meta.difference = meta.currentCount |-| (bit<20>)meta.currentCollision;
            if(meta.difference>100){
                meta.difference=100;
            }
            replace0.apply();
        }  


        STAGE_Array(1, 104w11111111111111111111);
        STAGE_Array(2, 104w22222222222222222222);
        STAGE_Array(3, 104w33333333333333333333);
        STAGE_Array(4, 104w44444444444444444444);
        
        forward_spec();

    }
}



control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) { apply{} }


V1Switch(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser() ) main;

