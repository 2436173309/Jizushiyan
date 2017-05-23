`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:43:17 05/02/2017 
// Design Name: 
// Module Name:    SingleCPU 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module SingleCPU(
    input CLK,
    input Reset,
    output [5:0] op,
	 output [4:0] rs,
	 output [4:0] rt,
	 output [4:0] rd,
	 output [15:0] immediate,
    output [31:0] ReadData1,
    output [31:0] ReadData2,
	 output [31:0] WriteData,
	 output [31:0] DataOut,
    output [31:0] currentAddress,
    output [31:0] result,
	 output PCWre
    );

	// ������ʱ����
   wire [31:0] B, newAddress;
   wire [31:0] currentAddress_4, extendImmediate, currentAddress_immediate, outAddress, ALUM2DR;	  
   wire [4:0] WriteReg;  
	wire [25:0] address;
	
   wire zero, ALUSrcB, ALUM2Reg, RegWre, WrRegData, InsMemRW, DataMemRW, IRWre;
	wire [1:0] ExtSel, PCSrc, RegOut;
	wire [2:0] ALUOp;
	
	// �Ĵ������ֵ
	wire [31:0] RegReadData1, RegReadData2, RegResult, RegDataOut;
	
	/*module ControlUnit(
	 input CLK,              // ʱ��
	 input reset,            // �����ź�
    input [5:0] op,         // op������
    input zero,             // ALU��zero���
	 
	 // һ�ѿ����ź�
    output reg PCWre,           // (PC)PC�Ƿ���ģ����Ϊ0��PC�����ģ�
										  // ���⣬��D_Tri == 000״̬֮�⣬����״̬Ҳ���ܸı�PC��ֵ��
    output reg ALUSrcB,         // ��·ѡ����
    output reg ALUM2Reg,        // ��·ѡ����
    output reg RegWre,          // (RF)дʹ���źţ�Ϊ1ʱ����ʱ��������д��
	 output reg WrRegData,       // 2·ѡ�������ж�����д���Ƿ�ΪPCָ����Ϊ1�����ǣ�jar�õ�
    output reg InsMemRW,        // (IM)��д�����źţ�1Ϊд��0λ�����̶�Ϊ0
    output reg DataMemRW,       // (DM)���ݴ洢����д�����źţ�Ϊ1д��Ϊ0��
	 output reg IRWre,           // �Ĵ���дʹ�ܣ���ʱûʲô�ã��̶�Ϊ1
    output reg[1:0] ExtSel,     // (EXT)���Ʋ�λ�����Ϊ1�����з�����չ�����Ϊ0��ȫ��0
	 output reg[1:0] PCSrc,      // 4·ѡ������ѡ��PCָ����Դ
    output reg[1:0] RegOut,     // 4·ѡ�������ж�д�Ĵ�����ַ����Դ
    output reg[2:0] ALUOp       // (ALU)ALU�������� 
    );*/
	ControlUnit cu(CLK, Reset, op, zero, PCWre, ALUSrcB, ALUM2Reg,
		RegWre, WrRegData, InsMemRW, DataMemRW, IRWre, ExtSel, PCSrc, RegOut, ALUOp);
	
	/*module PC(
    input CLK,                         // ʱ��
    input Reset,                       // �����ź�
    input PCWre,                       // PC�Ƿ���ģ����Ϊ0��PC������
    input [31:0] newAddress,           // ��ָ��
    output reg[31:0] currentAddress    // ��ǰָ��
    );*/
	PC pc(CLK, Reset, PCWre, newAddress, currentAddress);
	
	/*module InstructionMemory(
	 input InsMemRW,            // ��д�����źţ�1Ϊд��0λ��
    input [31:0] IAddr,        // ָ���ַ�������
	 //input IDataIn,           // û�õ� 
	 
	 input CLK,                  // ʱ���ź�
	 input IRWre,                // ����Ĵ���дʹ��
	 
    output reg[5:0] op,
    output reg[4:0] rs,
    output reg[4:0] rt,
    output reg[4:0] rd,
    output reg[15:0] immediate, // ָ������ʱ�����
	 output reg[25:0] address
    );*/
	InstructionMemory im(InsMemRW, currentAddress, CLK, IRWre, op, rs, rt, rd, immediate, address);
	
	/*module RegisterFile(
	 input CLK,                       // ʱ��
	 input RegWre,                    // дʹ���źţ�Ϊ1ʱ����ʱ��������д��
    input [4:0] rs,                  // rs�Ĵ�����ַ����˿�
    input [4:0] rt,                  // rt�Ĵ�����ַ����˿�
    input [4:0] WriteReg,            // ������д��ļĴ����˿ڣ����ַ��Դrt��rd�ֶ�
    input [31:0] WriteData,          // д��Ĵ�������������˿�
	 output [31:0] ReadData1,         // rs��������˿�
    output [31:0] ReadData2          // rt��������˿�
    );*/
	RegisterFile rf(CLK, RegWre, rs, rt, WriteReg, WriteData, ReadData1, ReadData2);
	
	/*module ALU(
	 input [2:0] ALUOp,           // ALU��������
    input [31:0] A,              // ����1
    input [31:0] B,              // ����2
    output reg zero,             // ������result�ı�־��resultΪ0���1���������0
	 output reg[31:0] result      // ALU������
    );*/
	ALU alu(ALUOp, ReadData1, B, zero, result);
	
	/*module SignZeroExtend(
    input [1:0]ExtSel,              // ���Ʋ�λ�����Ϊ1X�����з�����չ
	                                 // ���Ϊ01��immediateȫ��0
	                                 // ���Ϊ00��saȫ��0
    input [15:0] immediate,         // 16λ������
    output [31:0] extendImmediate   // �����32λ������
    );*/
	SignZeroExtend sze(ExtSel, immediate, extendImmediate);
	
	/*module DataMemory(
	 input DataMemRW,            // ���ݴ洢����д�����źţ�Ϊ1д��Ϊ0��
    input [31:0] DAddr,         // ���ݴ洢����ַ����˿�
    input [31:0] DataIn,        // ���ݴ洢����������˿�
    output reg [31:0] DataOut   // ���ݴ洢����������˿�
    );*/
	DataMemory dm(DataMemRW, RegResult, RegReadData2, DataOut);
	
	/*module PCJUMP(
    input [31:0] PC0,          // ָ��
    input [25:0] inAddress,    // �����ַ
    output [31:0] outAddress   // �����ַ(ָ��)
    );*/
	PCJUMP pcj(currentAddress, address, outAddress);
	
	assign currentAddress_4 = currentAddress + 4;
	assign currentAddress_immediate = currentAddress_4 + (extendImmediate << 2);
	
	// ��ת�Ĵ���
	WireToReg wtrA(CLK, 1, ReadData1, RegReadData1);
	WireToReg wtrB(CLK, 1, ReadData2, RegReadData2);
	WireToReg wtrALU(CLK, 1, result, RegResult);
	WireToReg wtrMEM(CLK, 1, DataOut, RegDataOut);

	// 2·ѡ����
	MUX2L_32 mux2_1(WrRegData, currentAddress_4, ALUM2DR, WriteData);
	MUX2L_32 mux2_2(ALUSrcB, RegReadData2, extendImmediate, B);
	MUX2L_32 mux2_3(ALUM2Reg, result, RegDataOut, ALUM2DR);
	
	// 4·ѡ����
	MUX4L_5 mux4_1(RegOut, 5'b11111, rt, rd, 5'b00000, WriteReg);
	MUX4L_32 mux4_2(PCSrc, currentAddress_4, currentAddress_immediate,
		ReadData1, outAddress, newAddress);
	
endmodule
