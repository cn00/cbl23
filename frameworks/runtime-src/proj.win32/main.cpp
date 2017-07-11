#include "stdafx.h"
#include "main.h"
#include "resource.h"
#include "platform/win32/SimulatorWin.h"
#include "AppDelegate.h"

int WINAPI _tWinMain(HINSTANCE hInstance,
	HINSTANCE hPrevInstance,
	LPTSTR    lpCmdLine,
	int       nCmdShow)
{
	AllocConsole();
	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);

	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
	auto app = AppDelegate();
    auto simulator = SimulatorWin::getInstance();
    auto ret = simulator->run();
	FreeConsole();
	return ret;
}
