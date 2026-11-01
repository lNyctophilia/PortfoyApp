#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <windowsx.h>
#include <dwmapi.h>
#include <shlobj.h>
#include <wrl.h>
#include <string>
#include "resource.h"
#include "WebView2.h"

#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")

using namespace Microsoft::WRL;

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif

// Global variables
const wchar_t g_szClassName[] = L"PortfoyApp_WindowClass";
const wchar_t g_szAppTitle[] = L"PortfoyApp";
const wchar_t g_szTargetUrl[] = L"https://lnyctophilia.github.io/PortfoyApp/";
const wchar_t g_szMutexName[] = L"Local\\PortfoyApp_SingleInstance_Mutex";

HWND g_hWnd = nullptr;
ComPtr<ICoreWebView2Controller> g_controller = nullptr;
ComPtr<ICoreWebView2> g_webView = nullptr;
bool g_isFullscreen = false;
WINDOWPLACEMENT g_wpPrev = { sizeof(g_wpPrev) };

// Minimum window constraints
const int MIN_WINDOW_WIDTH = 800;
const int MIN_WINDOW_HEIGHT = 600;

void ToggleFullscreen(HWND hWnd) {
    DWORD dwStyle = GetWindowLong(hWnd, GWL_STYLE);
    if (!g_isFullscreen) {
        MONITORINFO mi = { sizeof(mi) };
        if (GetWindowPlacement(hWnd, &g_wpPrev) &&
            GetMonitorInfo(MonitorFromWindow(hWnd, MONITOR_DEFAULTTOPRIMARY), &mi)) {
            SetWindowLong(hWnd, GWL_STYLE, dwStyle & ~WS_OVERLAPPEDWINDOW);
            SetWindowPos(hWnd, HWND_TOP,
                         mi.rcMonitor.left, mi.rcMonitor.top,
                         mi.rcMonitor.right - mi.rcMonitor.left,
                         mi.rcMonitor.bottom - mi.rcMonitor.top,
                         SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
            g_isFullscreen = true;
        }
    } else {
        SetWindowLong(hWnd, GWL_STYLE, dwStyle | WS_OVERLAPPEDWINDOW);
        SetWindowPlacement(hWnd, &g_wpPrev);
        SetWindowPos(hWnd, NULL, 0, 0, 0, 0,
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                     SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
        g_isFullscreen = false;
    }
}

void ResizeWebView() {
    if (g_controller != nullptr && g_hWnd != nullptr) {
        RECT bounds;
        GetClientRect(g_hWnd, &bounds);
        g_controller->put_Bounds(bounds);
    }
}

void ClearCacheAndReload() {
    if (g_webView == nullptr) return;

    ComPtr<ICoreWebView2_13> webView13;
    if (SUCCEEDED(g_webView.As(&webView13))) {
        ComPtr<ICoreWebView2Profile> profile;
        if (SUCCEEDED(webView13->get_Profile(&profile))) {
            ComPtr<ICoreWebView2Profile2> profile2;
            if (SUCCEEDED(profile.As(&profile2))) {
                profile2->ClearBrowsingDataAll(
                    Callback<ICoreWebView2ClearBrowsingDataCompletedHandler>(
                        [](HRESULT) -> HRESULT {
                            if (g_webView != nullptr) {
                                g_webView->Navigate(g_szTargetUrl);
                            }
                            return S_OK;
                        }
                    ).Get()
                );
                return;
            }
        }
    }

    // Fallback if ClearBrowsingDataAll is not supported
    g_webView->Reload();
}

void InitWebView(HWND hWnd) {
    // Get Local AppData path for isolated user data directory
    WCHAR localAppData[MAX_PATH];
    std::wstring userDataFolder;
    if (SUCCEEDED(SHGetFolderPathW(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, localAppData))) {
        userDataFolder = std::wstring(localAppData) + L"\\PortfoyApp\\WebView2Data";
    }

    // Initialize WebView2 environment
    HRESULT hr = CreateCoreWebView2EnvironmentWithOptions(
        nullptr,
        userDataFolder.empty() ? nullptr : userDataFolder.c_str(),
        nullptr,
        Callback<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
            [hWnd](HRESULT result, ICoreWebView2Environment* env) -> HRESULT {
                if (FAILED(result) || env == nullptr) {
                    MessageBoxW(
                        hWnd,
                        L"Microsoft Edge WebView2 başlatılamadı.\nLütfen Microsoft Edge WebView2 Runtime kurulu olduğundan emin olun.",
                        L"PortfoyApp - Hata",
                        MB_OK | MB_ICONERROR
                    );
                    return result;
                }

                // Create WebView2 Controller
                env->CreateCoreWebView2Controller(
                    hWnd,
                    Callback<ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
                        [hWnd](HRESULT result, ICoreWebView2Controller* controller) -> HRESULT {
                            if (FAILED(result) || controller == nullptr) {
                                return result;
                            }

                            g_controller = controller;
                            g_controller->get_CoreWebView2(&g_webView);

                            // Configure modern WebView2 settings
                            ComPtr<ICoreWebView2Settings> settings;
                            if (SUCCEEDED(g_webView->get_Settings(&settings))) {
                                settings->put_IsScriptEnabled(TRUE);
                                settings->put_AreDefaultScriptDialogsEnabled(TRUE);
                                settings->put_IsWebMessageEnabled(TRUE);
                                settings->put_IsStatusBarEnabled(FALSE);
                                settings->put_AreDevToolsEnabled(TRUE);
                                settings->put_AreDefaultContextMenusEnabled(TRUE);
                            }

                            // Match WebView default background with app dark theme (#0A1128 -> RGB 10, 17, 40)
                            ComPtr<ICoreWebView2Controller2> controller2;
                            if (SUCCEEDED(g_controller.As(&controller2))) {
                                COREWEBVIEW2_COLOR bgColor = { 255, 10, 17, 40 }; // ARGB
                                controller2->put_DefaultBackgroundColor(bgColor);
                            }

                            // Resize WebView to fill client area and show it
                            ResizeWebView();
                            g_controller->put_IsVisible(TRUE);

                            // Register message handler for Web -> Native communication (hard reload & cache clear)
                            EventRegistrationToken webMessageToken;
                            g_webView->add_WebMessageReceived(
                                Callback<ICoreWebView2WebMessageReceivedEventHandler>(
                                    [](ICoreWebView2* sender, ICoreWebView2WebMessageReceivedEventArgs* args) -> HRESULT {
                                        LPWSTR messageRaw = nullptr;
                                        if (SUCCEEDED(args->TryGetWebMessageAsString(&messageRaw)) && messageRaw != nullptr) {
                                            std::wstring msg(messageRaw);
                                            CoTaskMemFree(messageRaw);
                                            if (msg == L"clear_cache_and_reload" || msg == L"hard_reload") {
                                                ClearCacheAndReload();
                                            }
                                        }
                                        return S_OK;
                                    }
                                ).Get(),
                                &webMessageToken
                            );

                            // Navigate to PortfoyApp hosted site
                            g_webView->Navigate(g_szTargetUrl);

                            return S_OK;
                        }
                    ).Get()
                );
                return S_OK;
            }
        ).Get()
    );

    if (FAILED(hr)) {
        MessageBoxW(
            hWnd,
            L"Microsoft Edge WebView2 Runtime bulunamadı.\nhttps://developer.microsoft.com/en-us/microsoft-edge/webview2/ adresinden indirebilirsiniz.",
            L"PortfoyApp",
            MB_OK | MB_ICONWARNING
        );
    }
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_SIZE:
        ResizeWebView();
        return 0;

    case WM_SETFOCUS:
        if (g_controller != nullptr) {
            g_controller->MoveFocus(COREWEBVIEW2_MOVE_FOCUS_REASON_PROGRAMMATIC);
        }
        return 0;

    case WM_GETMINMAXINFO: {
        LPMINMAXINFO lpMMI = (LPMINMAXINFO)lParam;
        lpMMI->ptMinTrackSize.x = MIN_WINDOW_WIDTH;
        lpMMI->ptMinTrackSize.y = MIN_WINDOW_HEIGHT;
        return 0;
    }

    case WM_KEYDOWN: {
        // Keyboard shortcuts
        bool ctrlPressed = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
        bool shiftPressed = (GetKeyState(VK_SHIFT) & 0x8000) != 0;

        if (wParam == VK_F5 || (ctrlPressed && wParam == 'R')) {
            if (g_webView != nullptr) {
                if (shiftPressed || ctrlPressed) {
                    ClearCacheAndReload();
                } else {
                    g_webView->Reload();
                }
            }
            return 0;
        }

        if (wParam == VK_F11) {
            ToggleFullscreen(hWnd);
            return 0;
        }
        break;
    }

    case WM_SYSKEYDOWN: {
        if (wParam == VK_LEFT && (GetKeyState(VK_MENU) & 0x8000)) {
            if (g_webView != nullptr) {
                BOOL canGoBack = FALSE;
                g_webView->get_CanGoBack(&canGoBack);
                if (canGoBack) g_webView->GoBack();
            }
            return 0;
        }
        if (wParam == VK_RIGHT && (GetKeyState(VK_MENU) & 0x8000)) {
            if (g_webView != nullptr) {
                BOOL canGoForward = FALSE;
                g_webView->get_CanGoForward(&canGoForward);
                if (canGoForward) g_webView->GoForward();
            }
            return 0;
        }
        break;
    }

    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }

    return DefWindowProc(hWnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // Single instance mutex check
    HANDLE hMutex = CreateMutexW(NULL, TRUE, g_szMutexName);
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        HWND existingWnd = FindWindowW(g_szClassName, NULL);
        if (existingWnd != nullptr) {
            if (IsIconic(existingWnd)) {
                ShowWindow(existingWnd, SW_RESTORE);
            }
            SetForegroundWindow(existingWnd);
        }
        if (hMutex) CloseHandle(hMutex);
        return 0;
    }

    // Initialize COM
    HRESULT hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);

    // Register Window Class
    WNDCLASSEXW wcex = { sizeof(WNDCLASSEXW) };
    wcex.style = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc = WndProc;
    wcex.hInstance = hInstance;
    wcex.hIcon = LoadIconW(hInstance, MAKEINTRESOURCEW(IDI_APPICON));
    wcex.hCursor = LoadCursorW(NULL, IDC_ARROW);
    // Background brush matches #0A1128 (dark navy)
    wcex.hbrBackground = CreateSolidBrush(RGB(10, 17, 40));
    wcex.lpszClassName = g_szClassName;
    wcex.hIconSm = LoadIconW(hInstance, MAKEINTRESOURCEW(IDI_APPICON));

    if (!RegisterClassExW(&wcex)) {
        return 1;
    }

    // Default window dimensions: 1280x820 (comfortably large for desktop portfolio view)
    int defaultWidth = 1280;
    int defaultHeight = 820;
    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);
    int posX = (screenWidth > defaultWidth) ? (screenWidth - defaultWidth) / 2 : 50;
    int posY = (screenHeight > defaultHeight) ? (screenHeight - defaultHeight) / 2 : 50;

    // Create Main Window
    g_hWnd = CreateWindowExW(
        WS_EX_APPWINDOW,
        g_szClassName,
        g_szAppTitle,
        WS_OVERLAPPEDWINDOW,
        posX, posY, defaultWidth, defaultHeight,
        nullptr, nullptr, hInstance, nullptr
    );

    if (!g_hWnd) {
        return 1;
    }

    // Enable Windows 11 Dark Mode Titlebar
    BOOL darkMode = TRUE;
    DwmSetWindowAttribute(g_hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &darkMode, sizeof(darkMode));
    // Fallback for older Win10 builds
    DwmSetWindowAttribute(g_hWnd, 19, &darkMode, sizeof(darkMode));

    // Enable Windows 11 Rounded Corners (DWMWCP_ROUND)
    DWM_WINDOW_CORNER_PREFERENCE cornerPref = DWMWCP_ROUND;
    DwmSetWindowAttribute(g_hWnd, DWMWA_WINDOW_CORNER_PREFERENCE, &cornerPref, sizeof(cornerPref));

    // Set Window Icons
    SendMessage(g_hWnd, WM_SETICON, ICON_BIG, (LPARAM)wcex.hIcon);
    SendMessage(g_hWnd, WM_SETICON, ICON_SMALL, (LPARAM)wcex.hIconSm);

    // Show window maximized by default
    ShowWindow(g_hWnd, SW_MAXIMIZE);
    UpdateWindow(g_hWnd);

    // Initialize WebView2
    InitWebView(g_hWnd);

    // Message loop
    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    // Clean up
    if (hMutex) {
        ReleaseMutex(hMutex);
        CloseHandle(hMutex);
    }
    CoUninitialize();

    return (int)msg.wParam;
}
