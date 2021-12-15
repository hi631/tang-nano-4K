using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.Collections;
using System.Runtime.InteropServices;
using System.Threading;

namespace JtagTerm
{
	public partial class Form1 : Form
	{
		[DllImport("AID.dll")]
		static extern uint FT_ListDevices();
		[DllImport("AID.dll")]
		static extern uint FT_Open();
		[DllImport("AID.dll")]
		static extern uint FT_Close();
		[DllImport("AID.dll")]
		static extern uint FT_Write([MarshalAs(UnmanagedType.LPArray)] byte[] p_data,ulong size);
		[DllImport("AID.dll")]
		static extern uint FT_GetStatus(ref ulong rxsize, ref ulong txsize);
		[DllImport("AID.dll")]
		static extern uint FT_SetBitMode(byte mask, byte enable);
		[DllImport("AID.dll")]
		static extern uint FT_Read([MarshalAs(UnmanagedType.LPArray)] byte[] p_data,ulong size);
		[DllImport("AID.dll")]
		static extern uint FT_EE_Read(ref ushort vid,ref ushort pid, ref ushort power);
		[DllImport("AID.dll")]
		static extern uint FT_EE_Program(ushort power);
		[DllImport("AID.dll")]
		static extern uint FT_EE_ProgramToDefault();
		[DllImport("AID.dll")]
		static extern uint KCAN_Send(uint channel, uint id, uint dlc, [MarshalAs(UnmanagedType.LPArray)] byte[] p_data);
		[DllImport("AID.dll")]
		static extern uint KCAN_Receive(ref uint channel, ref uint id, ref uint dlc, [MarshalAs(UnmanagedType.LPArray)] byte[] p_data);
		[DllImport("AID.dll")]
		static extern uint KCAN_Init(uint baudraute);
		private System.Windows.Forms.TextBox tbx_No_Devices;
		private TextBox textBox1;
		private Button btn_start;
		private System.Windows.Forms.Timer timer1;
		private Label label1;
		private Button button1;
		//private IContainer components;

		public Form1()
		{
			InitializeComponent();
		}

		public const int rbfmax = 256;
		byte[] kinbuf = new byte[rbfmax];
		byte[] dspbuf = new byte[rbfmax];
		int kinbwp =0, kinbrp = 0, dspbwp = 0, dspbrp = 0;
		private void disp_loop() {
			char dch;
			for(;;){
				string dmsg = "";
				while (dspbrp != dspbwp) {
					dch = (char)dspbuf[dspbrp++]; dmsg = dmsg+(dch.ToString());
					if(dspbrp>=rbfmax) dspbrp = 0;
				} 
				if(dmsg!="") msgout(dmsg);
				Thread.Sleep(20);
			}
		}
		
		private void ftrx_loop() {
			byte[] init=new byte[4];
			byte[] sdata=new Byte[64];
			byte[] rdata=new Byte[64];
			int dmax = 64;
			byte dt;
			init[0] = 0x31; init[1] = (byte)(dmax-1); init[2] = 0x00;
			for (; ; ) {
				for(int i=0; i<dmax; i++) {
					if(kinbwp!=kinbrp) {
						sdata[i] = kinbuf[kinbrp]; kinbrp++;
						if(kinbrp>=rbfmax) kinbrp = 0x00;
					} else sdata[i] = 0;
					rdata[i] = 0;
				}

				FT_Open();
				FT_Write(init,3);	// Write文字数セット(初期化)
				FT_Write(sdata,(ulong)dmax); FT_Read(rdata, (ulong)dmax); 
				FT_Close();

				for(int i=0; i<dmax; i++){
					dt = rdata[i];
					if(dt>0x00 && dt<0x80){ 
						dspbuf[dspbwp++] = dt;
						if(dspbwp>=rbfmax) dspbwp = 0;
					}
				}
				Thread.Sleep(20);
			}
		}
			
        private void msgfmout(string msg) { 
			textBox1.AppendText(msg); 
			while ( textBox1.Lines.Length >= 100 ) {	// Max 100Line 行数数制限
				textBox1.Text = textBox1.Text.Remove( 0, textBox1.Text.IndexOf( "\n" ) + 1 );
			} 
			textBox1.SelectionStart = textBox1.Text.Length;	// 末尾へ
			textBox1.ScrollToCaret();
		}
		public delegate void DelegateUpdateText(string msg);
        private void msgout(string msg) {	// スレッドからDelegate経由の表示
            if (this.InvokeRequired) {  this.Invoke(new DelegateUpdateText(this.msgfmout), msg); } 
			else this.msgfmout(msg);		// 自スレッドの場合はダイレクト
        }

		private void stask() {
			//msgout(Thread.CurrentThread.Name +" Start \r\n");
			try { ftrx_loop(); }
			catch (ThreadInterruptedException){ }
			finally { }
			//msgout(Thread.CurrentThread.Name+" normal.end\r\n");
		}
		private void dtask() {
			//msgout(Thread.CurrentThread.Name +" Start \r\n");
			try { disp_loop(); }
			catch (ThreadInterruptedException){ }
			finally { }
			//msgout(Thread.CurrentThread.Name+" normal.end\r\n");
		}

		Thread sthread, dthread;
		private void timer1_Tick(object sender, EventArgs e) {
			if (taskrun==0) {	// 接続デバイス数を表示
				tbx_No_Devices.Text=Convert.ToString(FT_ListDevices());
			}
		}

		private void taskstop()	{
			if(taskrun!=0){
				taskrun = 0;
				sthread.Interrupt(); dthread.Interrupt();	// thread.Stop
				btn_start.BackColor = Color.LightGray;
				Application.DoEvents();
			}
		}

		int taskrun = 0;
		private void Term_FT() {
			if(taskrun==0) {
				uint status = FT_Open(); FT_Close();	// 接続確認
				if(status==0) {
					taskrun = 1; textBox1.Clear();
					sthread = new Thread(new ThreadStart(stask)); sthread.Name = "Tasks";
					dthread = new Thread(new ThreadStart(dtask)); dthread.Name = "Taskd";
					sthread.Start(); dthread.Start();	// thread.Start
					btn_start.Text = "Term Stop";
					btn_start.BackColor = Color.LightGreen;
				} else btn_start.BackColor = Color.Red;
			} else {
				taskstop();
				btn_start.Text = "Term Start";
			}
		}

		private void textBox1_KeyPress(object sender, KeyPressEventArgs e) {
			kinbuf[kinbwp] = (byte)e.KeyChar; kinbwp++;
			if(kinbwp>=rbfmax) kinbwp = 0;
			e.Handled = true;
		}

		private void btn_start_Click(object sender, EventArgs e) {
			Term_FT();
		}

		private void button1_Click(object sender, EventArgs e) {
			Application.Exit();
		}

		private void Form_Load(object sender, EventArgs e) {
			timer1.Enabled = true;
		}

		private void Form_FormClosing(object sender, FormClosingEventArgs e) {
			taskstop();
		}
	}
}
