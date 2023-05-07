extends PythonBridge

func run():
	%GameScene._on_run_stop_button_toggled(true)

func stop():
	%GameScene._on_run_stop_button_toggled(false)

func reload():
	%GameScene._on_reset_button_pressed()
