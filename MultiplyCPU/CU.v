`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:11:08 05/03/2017 
// Design Name: 
// Module Name:    CU 
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
module ControlUnit(
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
    );
	
	// ����״̬���궨��
	parameter [2:0] 
		IF = 3'b000,
		ID = 3'b001,
		EXELS = 3'b010,
		MEM = 3'b011,
		WBL = 3'b100,
		EXEBR = 3'b101,
		EXEAL = 3'b110,
		WBAL = 3'b111;
	
	// ָ��궨�壬������Щָ��Ϊ�ؼ��֣����ȫ�����ַ���д
	parameter [5:0]
		Add = 6'b000000,
		Addi = 6'b000010, 
		Sub = 6'b000001, 
      Ori = 6'b010010,  
		And = 6'b010001,
		Or = 6'b010000,
      Sll = 6'b011000,  
      Move = 6'b100000,  
      Slt = 6'b100111,  
      Sw = 6'b110000,  
      Lw = 6'b110001,  
      Beq = 6'b110100,  
      J = 6'b111000,  
      Jr = 6'b111001,   
      Jal = 6'b111010,  
      Halt = 6'b111111; 
	
	// 3λD������������8��״̬
	/* 000 -> IF
	 * 001 -> ID
	 * 010 -> EXELS
	 * 011 -> MEM
	 * 100 -> WBL
	 * 101 -> EXEBR
	 * 110 -> EXEAL
	 * 111 -> WBAL
	 */
	reg [2:0] D_Tri;
	
	// ���и��ָ�ֵ
	initial 
	 begin
		PCWre = 0;
		ALUSrcB = 0;
		ALUM2Reg = 0;
		RegWre = 0;
		WrRegData = 0;
		// no change
		InsMemRW = 0;
		DataMemRW = 0;
		// no change
		IRWre = 1;
		ExtSel = 0;
		PCSrc = 0;
		RegOut = 0;
		ALUOp = 0;
		D_Tri = 0;
    end

	// D�������仯��PS��Ϊ�˱��⾺��ð�գ�����ֵ�仯��Ϊ�½��ش���
	// PCWre��RegWre��DataMemRW�ı仯Ӱ��ܴ�Ҫ������д
	always@(negedge CLK or posedge reset)
	 begin
		// ��������
		if (reset)  
		 begin
			D_Tri = IF;
			PCWre = 0;
			RegWre = 0;
		 end
		else
		 begin
			case (D_Tri)
				// IF -> ID
				IF:
				 begin
					D_Tri <= ID;
					// ��ֹдָ��Ĵ��������ڴ�
					PCWre = 0;
					RegWre = 0;
					DataMemRW = 0;
				 end
				// ID -> EXE
				ID:
				 begin
					case (op)
						// �����beqָ�����EXEBR
						Beq:  D_Tri <= EXEBR;
						// �����sw��lwָ�����EXELS
						Sw, Lw:  D_Tri <= EXELS;
						// �����j��jal��jr��halt������IF
						J, Jal, Jr, Halt:
						 begin
						   D_Tri = IF;
							// ���ָ����halt����ֹдָ��
							if (op == Halt)  PCWre = 0;  
							else  PCWre = 1;
							// ���ָ����jal������д�Ĵ���
							if (op == Jal)  RegWre = 1;
							else  RegWre = 0;
						 end
						// ����������EXEAL
						default:  D_Tri = EXEAL;
					endcase
				 end
				// EXEAL -> WBAL
				EXEAL:
				 begin
					D_Tri = WBAL;
					// ����д�Ĵ���
					RegWre = 1; 
				 end 
				// EXELS -> MEM
				EXELS:  
				 begin
					D_Tri = MEM;
					// ���ָ��Ϊsw������д�ڴ�
					if (op == Sw)  DataMemRW = 1;
				 end
				// MEM -> WBL
				MEM:
				 begin
					// ���ָ��Ϊsw��MEM -> IF
					if (op == Sw)
					 begin
						D_Tri = IF;
						// ����дָ��
						PCWre = 1;
					 end
					// ���ָ��Ϊlw��MEM -> WBL
					else
					 begin
						D_Tri = WBL;
						// ����д�Ĵ���
						RegWre = 1;
					 end
				 end 
				// ���� -> IF
				default:
				 begin
					D_Tri = IF;
					// ����дָ��
					PCWre = 1;
					// ��ֹд�Ĵ���
					RegWre = 0;
				 end
			endcase
		 end
	 end

	// һ���ź�
	always@(op or zero)
    begin  
      case(op) 
			Add:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 0;
				ALUM2Reg = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 00;
				RegOut = 10;
				ALUOp = 000;
			 end
			Addi:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 1;
				ALUM2Reg = 0;
				WrRegData = 1;
				ExtSel = 10;
				PCSrc = 00;
				RegOut = 01;
				ALUOp = 000;
			 end
			Sub:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 0;
				ALUM2Reg = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 00;
				RegOut = 10;
				ALUOp = 001;
			 end
			Ori:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 1;
				ALUM2Reg = 0;
				WrRegData = 1;
				ExtSel = 01;
				PCSrc = 00;
				RegOut = 01;
				ALUOp = 101;
			 end
			And:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 0;
				ALUM2Reg = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 00;
				RegOut = 10;
				ALUOp = 110;
			 end
			Or:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 0;
				ALUM2Reg = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 00;
				RegOut = 10;
				ALUOp = 101;
			 end
			Sll:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 1;
				ALUM2Reg = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 00;
				RegOut = 10;
				ALUOp = 100;
			 end
			Move:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 0;
				ALUM2Reg = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 00;
				RegOut = 10;
				ALUOp = 000;
			 end
			Slt:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 0;
				ALUM2Reg = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 00;
				RegOut = 10;
				ALUOp = 010;
			 end
			Sw:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 1;
				ALUM2Reg = 0;
				RegWre = 0;
				WrRegData = 1;
				ExtSel = 10;
				PCSrc = 00;
				RegOut = 00;
				ALUOp = 000;
			 end
			Lw:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 1;
				ALUM2Reg = 1;
				WrRegData = 1;
				ExtSel = 10;
				PCSrc = 00;
				RegOut = 01;
				ALUOp = 000;
			 end
			Beq:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				if (zero)  PCSrc = 01;
				else  PCSrc = 00;
				ALUSrcB = 0;
				ALUM2Reg = 0;
				RegWre = 0;
				WrRegData = 1;
				 
				ExtSel = 10;
				RegOut = 00;
				ALUOp = 001;
			 end
			J:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 0;
				ALUM2Reg = 0;
				RegWre = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 11;
				RegOut = 00;
				ALUOp = 000;
			 end
			Jr:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 0;
				ALUM2Reg = 0;
				RegWre = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 10;
				RegOut = 00;
				ALUOp = 000;
			 end
			Jal:
          begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				ALUSrcB = 0;
				ALUM2Reg = 0;
				WrRegData = 0;
				ExtSel = 00;
				PCSrc = 11;
				RegOut = 00;
				ALUOp = 000;
			 end
			Halt:
			 begin   //���¶��ǿ��Ƶ�Ԫ�����Ŀ����ź�
				PCWre = 0;
				ALUSrcB = 0;
				ALUM2Reg = 0;
				RegWre = 0;
				WrRegData = 1;
				ExtSel = 00;
				PCSrc = 00;
				RegOut = 00;
				ALUOp = 000;
			 end
		endcase
	 end

endmodule
