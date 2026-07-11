xrun
	-timescale 1ns/1ps
	./uart_top.v
	./uart_tx.v
	./uart_rx.v
	./baud_gen.v
	./uart_tb.v
	-access +rwc
	-gui