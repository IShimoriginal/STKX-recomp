/**
 * @file        src/launcher/main.cpp
 * @brief       Zero-dependency native Win32 GUI Launcher for 首都高バトルX (Shutokou Battle X)
 */

#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <commctrl.h>

#include <cstdio>
#include <cwchar>
#include <string>

// Enable modern Windows Common Controls v6 visual styles without needing an external .manifest file
#if defined(_MSC_VER) || defined(__clang__)
#pragma comment(linker, \
    "\"/manifestdependency:type='win32' name='Microsoft.Windows.Common-Controls' " \
    "version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")
#endif

namespace {

constexpr wchar_t kWindowClassName[] = L"SBXLauncherWindowClass";
constexpr wchar_t kIniSection[] = L"Launcher";

enum ControlId : int {
  kIdLangCombo = 1000,
  kIdApiCombo = 1001,
  kIdInternalResCombo = 1002,
  kIdWindowResCombo = 1003,
  kIdUpscaleCombo = 1004,
  kIdFpsCombo = 1005,
  kIdVsyncCheck = 1006,
  kIdWindowedCheck = 1007,
  kIdLaunchBtn = 1008,
  kIdExitBtn = 1009,
};

struct OptionItem {
  const wchar_t* label_zh;
  const wchar_t* label_en;
  const wchar_t* arg_value;
};

struct ResolutionItem {
  const wchar_t* label;
  int width;
  int height;
};

constexpr const wchar_t* kLanguageOptions[] = {
    L"简体中文",
    L"English",
};

constexpr OptionItem kApiOptions[] = {
    {L"Direct3D 12", L"Direct3D 12", L"d3d12"},
    {L"Vulkan", L"Vulkan", L"vulkan"},
};

constexpr OptionItem kInternalResOptions[] = {
    {L"1x (1280 x 720)", L"1x (1280 x 720)", L"1"},
    {L"2x (2560 x 1440)", L"2x (2560 x 1440)", L"2"},
    {L"3x (3840 x 2160 / 4K)", L"3x (3840 x 2160 / 4K)", L"3"},
};

constexpr ResolutionItem kWindowResOptions[] = {
    {L"1280 x 720 (720p)", 1280, 720},
    {L"1600 x 900 (900p)", 1600, 900},
    {L"1920 x 1080 (1080p)", 1920, 1080},
    {L"2560 x 1440 (1440p)", 2560, 1440},
    {L"3840 x 2160 (4K)", 3840, 2160},
};

constexpr OptionItem kUpscaleOptions[] = {
    {L"Bilinear (双线性过滤)", L"Bilinear", L"bilinear"},
    {L"FSR 1 (AMD FidelityFX Super Resolution 1.0)", L"FSR 1 (AMD FidelityFX Super Resolution 1.0)",
     L"fsr"},
};

constexpr OptionItem kFpsOptions[] = {
    {L"30 FPS", L"30 FPS", L"30"},
    {L"40 FPS", L"40 FPS", L"40"},
    {L"60 FPS", L"60 FPS", L"60"},
    {L"120 FPS", L"120 FPS", L"120"},
    {L"无限制 (Unlimited)", L"Unlimited", L"0"},
};

struct LauncherState {
  HWND hwnd = nullptr;
  HWND title_label = nullptr;
  HWND lang_label = nullptr;
  HWND lang_combo = nullptr;
  HWND api_label = nullptr;
  HWND api_combo = nullptr;
  HWND internal_res_label = nullptr;
  HWND internal_res_combo = nullptr;
  HWND window_res_label = nullptr;
  HWND window_res_combo = nullptr;
  HWND upscale_label = nullptr;
  HWND upscale_combo = nullptr;
  HWND fps_label = nullptr;
  HWND fps_combo = nullptr;
  HWND vsync_check = nullptr;
  HWND windowed_check = nullptr;
  HWND launch_btn = nullptr;
  HWND exit_btn = nullptr;
  HFONT ui_font = nullptr;
  HFONT title_font = nullptr;
  UINT dpi = 96;
  int language = 0;  // 0 = Chinese, 1 = English
};

LauncherState g_state;

int ScaleDpi(int px) {
  return MulDiv(px, static_cast<int>(g_state.dpi), 96);
}

std::wstring GetModuleDirectory() {
  wchar_t buffer[MAX_PATH] = {};
  DWORD len = GetModuleFileNameW(nullptr, buffer, MAX_PATH);
  std::wstring path(buffer, len);
  size_t pos = path.find_last_of(L"\\/");
  if (pos != std::wstring::npos) {
    return path.substr(0, pos);
  }
  return L".";
}

bool FileExists(const std::wstring& path) {
  DWORD attr = GetFileAttributesW(path.c_str());
  return attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY);
}

std::wstring GetIniPath() {
  return GetModuleDirectory() + L"\\launcher.ini";
}

int ClampIndex(int value, int count) {
  if (value < 0 || value >= count) {
    return 0;
  }
  return value;
}

template <size_t N>
void RefreshOptionCombo(HWND combo, const OptionItem (&options)[N], int lang) {
  int sel = ClampIndex(static_cast<int>(SendMessageW(combo, CB_GETCURSEL, 0, 0)),
                       static_cast<int>(N));
  SendMessageW(combo, CB_RESETCONTENT, 0, 0);
  for (size_t i = 0; i < N; ++i) {
    const wchar_t* text = (lang == 1) ? options[i].label_en : options[i].label_zh;
    SendMessageW(combo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(text));
  }
  SendMessageW(combo, CB_SETCURSEL, sel, 0);
}

void ApplyLanguage(int lang) {
  g_state.language = ClampIndex(lang, static_cast<int>(std::size(kLanguageOptions)));
  const bool en = (g_state.language == 1);

  SetWindowTextW(g_state.hwnd,
                 en ? L"Shutokou Battle X - Launcher"
                    : L"首都高赛车X - 启动配置 (Shutokou Battle X Launcher)");
  SetWindowTextW(g_state.title_label,
                 en ? L"Shutokou Battle X" : L"首都高赛车X (Shutokou Battle X)");
  SetWindowTextW(g_state.lang_label, L"语言 / Language:");
  SetWindowTextW(g_state.api_label, en ? L"Graphics API:" : L"图形 API:");
  SetWindowTextW(g_state.internal_res_label, en ? L"Internal Res:" : L"内部分辨率:");
  SetWindowTextW(g_state.window_res_label, en ? L"Window Size:" : L"窗口分辨率:");
  SetWindowTextW(g_state.upscale_label, en ? L"Upscaling:" : L"上采样方式:");
  SetWindowTextW(g_state.fps_label, en ? L"Target FPS:" : L"目标帧率:");
  SetWindowTextW(g_state.vsync_check, en ? L"Enable VSync" : L"启用垂直同步 (VSync)");
  SetWindowTextW(g_state.windowed_check, en ? L"Windowed Mode" : L"窗口化启动 (Windowed)");
  SetWindowTextW(g_state.launch_btn, en ? L"Launch Game" : L"启动游戏");
  SetWindowTextW(g_state.exit_btn, en ? L"Exit" : L"退出");

  RefreshOptionCombo(g_state.upscale_combo, kUpscaleOptions, g_state.language);
  RefreshOptionCombo(g_state.fps_combo, kFpsOptions, g_state.language);
}

void LoadSavedSettings() {
  std::wstring ini = GetIniPath();
  int lang_idx = ClampIndex(GetPrivateProfileIntW(kIniSection, L"language", 0, ini.c_str()),
                            static_cast<int>(std::size(kLanguageOptions)));
  int api_idx = ClampIndex(GetPrivateProfileIntW(kIniSection, L"api", 0, ini.c_str()),
                           static_cast<int>(std::size(kApiOptions)));
  int int_res_idx = ClampIndex(GetPrivateProfileIntW(kIniSection, L"internal_res", 0, ini.c_str()),
                               static_cast<int>(std::size(kInternalResOptions)));
  int win_res_idx = ClampIndex(GetPrivateProfileIntW(kIniSection, L"window_res", 2, ini.c_str()),
                               static_cast<int>(std::size(kWindowResOptions)));
  int upscale_idx = ClampIndex(GetPrivateProfileIntW(kIniSection, L"upscale", 0, ini.c_str()),
                               static_cast<int>(std::size(kUpscaleOptions)));
  int fps_idx = ClampIndex(GetPrivateProfileIntW(kIniSection, L"fps", 2, ini.c_str()),
                           static_cast<int>(std::size(kFpsOptions)));
  int vsync = GetPrivateProfileIntW(kIniSection, L"vsync", 0, ini.c_str()) ? 1 : 0;
  int windowed = GetPrivateProfileIntW(kIniSection, L"windowed", 1, ini.c_str()) ? 1 : 0;

  SendMessageW(g_state.lang_combo, CB_SETCURSEL, lang_idx, 0);
  SendMessageW(g_state.api_combo, CB_SETCURSEL, api_idx, 0);
  SendMessageW(g_state.internal_res_combo, CB_SETCURSEL, int_res_idx, 0);
  SendMessageW(g_state.window_res_combo, CB_SETCURSEL, win_res_idx, 0);
  SendMessageW(g_state.upscale_combo, CB_SETCURSEL, upscale_idx, 0);
  SendMessageW(g_state.fps_combo, CB_SETCURSEL, fps_idx, 0);
  SendMessageW(g_state.vsync_check, BM_SETCHECK, vsync ? BST_CHECKED : BST_UNCHECKED, 0);
  SendMessageW(g_state.windowed_check, BM_SETCHECK, windowed ? BST_CHECKED : BST_UNCHECKED, 0);

  ApplyLanguage(lang_idx);
}

void SaveLanguageSetting(int lang_idx) {
  std::wstring ini = GetIniPath();
  wchar_t buf[32];
  swprintf_s(buf, L"%d", lang_idx);
  WritePrivateProfileStringW(kIniSection, L"language", buf, ini.c_str());
}

void SaveSettings(int lang_idx, int api_idx, int int_res_idx, int win_res_idx, int upscale_idx,
                  int fps_idx, bool vsync, bool windowed) {
  std::wstring ini = GetIniPath();
  auto write_int = [&ini](const wchar_t* key, int val) {
    wchar_t buf[32];
    swprintf_s(buf, L"%d", val);
    WritePrivateProfileStringW(kIniSection, key, buf, ini.c_str());
  };
  write_int(L"language", lang_idx);
  write_int(L"api", api_idx);
  write_int(L"internal_res", int_res_idx);
  write_int(L"window_res", win_res_idx);
  write_int(L"upscale", upscale_idx);
  write_int(L"fps", fps_idx);
  write_int(L"vsync", vsync ? 1 : 0);
  write_int(L"windowed", windowed ? 1 : 0);
}

std::wstring ResolveTargetExe(std::wstring& out_work_dir) {
  std::wstring dir = GetModuleDirectory();
  std::wstring candidate = dir + L"\\shutokou_battle_x.exe";
  if (FileExists(candidate)) {
    out_work_dir = dir;
    return candidate;
  }

  std::wstring fallback = dir + L"\\out\\win-amd64\\Release\\shutokou_battle_x.exe";
  if (FileExists(fallback)) {
    out_work_dir = dir + L"\\out\\win-amd64\\Release";
    return fallback;
  }

  out_work_dir = dir;
  return candidate;
}

void LaunchGame() {
  int lang_idx = ClampIndex(static_cast<int>(SendMessageW(g_state.lang_combo, CB_GETCURSEL, 0, 0)),
                            static_cast<int>(std::size(kLanguageOptions)));
  int api_idx = ClampIndex(static_cast<int>(SendMessageW(g_state.api_combo, CB_GETCURSEL, 0, 0)),
                           static_cast<int>(std::size(kApiOptions)));
  int int_res_idx = ClampIndex(
      static_cast<int>(SendMessageW(g_state.internal_res_combo, CB_GETCURSEL, 0, 0)),
      static_cast<int>(std::size(kInternalResOptions)));
  int win_res_idx = ClampIndex(
      static_cast<int>(SendMessageW(g_state.window_res_combo, CB_GETCURSEL, 0, 0)),
      static_cast<int>(std::size(kWindowResOptions)));
  int upscale_idx = ClampIndex(
      static_cast<int>(SendMessageW(g_state.upscale_combo, CB_GETCURSEL, 0, 0)),
      static_cast<int>(std::size(kUpscaleOptions)));
  int fps_idx = ClampIndex(static_cast<int>(SendMessageW(g_state.fps_combo, CB_GETCURSEL, 0, 0)),
                           static_cast<int>(std::size(kFpsOptions)));

  bool vsync = SendMessageW(g_state.vsync_check, BM_GETCHECK, 0, 0) == BST_CHECKED;
  bool windowed = SendMessageW(g_state.windowed_check, BM_GETCHECK, 0, 0) == BST_CHECKED;

  SaveSettings(lang_idx, api_idx, int_res_idx, win_res_idx, upscale_idx, fps_idx, vsync, windowed);

  const bool en = (lang_idx == 1);
  std::wstring work_dir;
  std::wstring exe_path = ResolveTargetExe(work_dir);
  if (!FileExists(exe_path)) {
    std::wstring msg =
        en ? (L"shutokou_battle_x.exe not found!\n\nExpected path:\n" + exe_path +
              L"\n\nPlease make sure Launcher.exe and shutokou_battle_x.exe are in the same folder.")
           : (L"未找到游戏主程序 shutokou_battle_x.exe！\n\n预期路径:\n" + exe_path +
              L"\n\n请确保 Launcher.exe 与 shutokou_battle_x.exe 位于同一目录。");
    MessageBoxW(g_state.hwnd, msg.c_str(), en ? L"Launch Failed" : L"启动失败",
                MB_ICONERROR | MB_OK);
    return;
  }

  const auto& win_res = kWindowResOptions[win_res_idx];
  const wchar_t* vulkan_extra_args =
      (api_idx == 1)
          ? L" --async_shader_compilation=false --vulkan_async_skip_incomplete_frames=false "
            L"--vulkan_submit_on_primary_buffer_end=false"
          : L"";
  wchar_t cmd_buf[1280] = {};
  swprintf_s(cmd_buf,
             L"\"%ls\" --gpu_backend=%ls --draw_resolution_scale_x=%ls --draw_resolution_scale_y=%ls "
             L"--window_width=%d --window_height=%d --present_effect=%ls --target_fps=%ls "
             L"--vsync=%ls --fullscreen=%ls%ls",
             exe_path.c_str(), kApiOptions[api_idx].arg_value,
             kInternalResOptions[int_res_idx].arg_value,
             kInternalResOptions[int_res_idx].arg_value, win_res.width, win_res.height,
             kUpscaleOptions[upscale_idx].arg_value, kFpsOptions[fps_idx].arg_value,
             vsync ? L"true" : L"false", windowed ? L"false" : L"true", vulkan_extra_args);

  STARTUPINFOW si = {};
  si.cb = sizeof(si);
  PROCESS_INFORMATION pi = {};

  if (!CreateProcessW(exe_path.c_str(), cmd_buf, nullptr, nullptr, FALSE, 0, nullptr,
                      work_dir.c_str(), &si, &pi)) {
    DWORD err = GetLastError();
    wchar_t err_msg[256] = {};
    swprintf_s(err_msg,
               en ? L"Failed to launch shutokou_battle_x.exe (Error code: %lu)"
                  : L"无法启动 shutokou_battle_x.exe (错误码: %lu)",
               err);
    MessageBoxW(g_state.hwnd, err_msg, en ? L"Launch Failed" : L"启动失败", MB_ICONERROR | MB_OK);
    return;
  }

  CloseHandle(pi.hThread);
  CloseHandle(pi.hProcess);
  DestroyWindow(g_state.hwnd);
}

void CreateUiControls(HWND hwnd) {
  NONCLIENTMETRICSW ncm = {};
  ncm.cbSize = sizeof(ncm);
  if (SystemParametersInfoW(SPI_GETNONCLIENTMETRICS, sizeof(ncm), &ncm, 0)) {
    ncm.lfMessageFont.lfHeight = -ScaleDpi(14);
    g_state.ui_font = CreateFontIndirectW(&ncm.lfMessageFont);

    LOGFONTW title_lf = ncm.lfMessageFont;
    title_lf.lfHeight = -ScaleDpi(18);
    title_lf.lfWeight = FW_BOLD;
    g_state.title_font = CreateFontIndirectW(&title_lf);
  } else {
    g_state.ui_font = static_cast<HFONT>(GetStockObject(DEFAULT_GUI_FONT));
    g_state.title_font = g_state.ui_font;
  }

  auto set_font = [](HWND ctrl, HFONT font) {
    SendMessageW(ctrl, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
  };

  int margin_x = ScaleDpi(24);
  int label_w = ScaleDpi(120);
  int combo_x = margin_x + label_w + ScaleDpi(10);
  int combo_w = ScaleDpi(300);
  int row_h = ScaleDpi(26);
  int row_step = ScaleDpi(38);
  int y = ScaleDpi(18);

  g_state.title_label = CreateWindowExW(0, L"STATIC", L"首都高赛车X (Shutokou Battle X)",
                                        WS_CHILD | WS_VISIBLE, margin_x, y, ScaleDpi(430),
                                        ScaleDpi(28), hwnd, nullptr, nullptr, nullptr);
  set_font(g_state.title_label, g_state.title_font);
  y += ScaleDpi(36);

  auto add_combo_row = [&](const wchar_t* label_text, int id, HWND& out_label,
                           auto& options, size_t count) -> HWND {
    out_label = CreateWindowExW(0, L"STATIC", label_text, WS_CHILD | WS_VISIBLE | SS_CENTERIMAGE,
                                margin_x, y, label_w, row_h, hwnd, nullptr, nullptr, nullptr);
    set_font(out_label, g_state.ui_font);

    HWND combo = CreateWindowExW(
        0, L"COMBOBOX", L"",
        WS_CHILD | WS_VISIBLE | WS_TABSTOP | CBS_DROPDOWNLIST | WS_VSCROLL, combo_x, y, combo_w,
        ScaleDpi(200), hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)), nullptr, nullptr);
    set_font(combo, g_state.ui_font);

    for (size_t i = 0; i < count; ++i) {
      SendMessageW(combo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(options[i].label_zh));
    }
    y += row_step;
    return combo;
  };

  // Language selector row at the top
  g_state.lang_label = CreateWindowExW(0, L"STATIC", L"语言 / Language:",
                                       WS_CHILD | WS_VISIBLE | SS_CENTERIMAGE, margin_x, y,
                                       label_w, row_h, hwnd, nullptr, nullptr, nullptr);
  set_font(g_state.lang_label, g_state.ui_font);
  g_state.lang_combo = CreateWindowExW(
      0, L"COMBOBOX", L"",
      WS_CHILD | WS_VISIBLE | WS_TABSTOP | CBS_DROPDOWNLIST | WS_VSCROLL, combo_x, y, combo_w,
      ScaleDpi(200), hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdLangCombo)), nullptr,
      nullptr);
  set_font(g_state.lang_combo, g_state.ui_font);
  for (const wchar_t* lang_name : kLanguageOptions) {
    SendMessageW(g_state.lang_combo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(lang_name));
  }
  y += row_step;

  g_state.api_combo = add_combo_row(L"图形 API:", kIdApiCombo, g_state.api_label, kApiOptions,
                                    std::size(kApiOptions));
  g_state.internal_res_combo =
      add_combo_row(L"内部分辨率:", kIdInternalResCombo, g_state.internal_res_label,
                    kInternalResOptions, std::size(kInternalResOptions));

  // Window resolution uses ResolutionItem
  g_state.window_res_label = CreateWindowExW(0, L"STATIC", L"窗口分辨率:",
                                             WS_CHILD | WS_VISIBLE | SS_CENTERIMAGE, margin_x, y,
                                             label_w, row_h, hwnd, nullptr, nullptr, nullptr);
  set_font(g_state.window_res_label, g_state.ui_font);
  g_state.window_res_combo = CreateWindowExW(
      0, L"COMBOBOX", L"",
      WS_CHILD | WS_VISIBLE | WS_TABSTOP | CBS_DROPDOWNLIST | WS_VSCROLL, combo_x, y, combo_w,
      ScaleDpi(200), hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdWindowResCombo)),
      nullptr, nullptr);
  set_font(g_state.window_res_combo, g_state.ui_font);
  for (const auto& res : kWindowResOptions) {
    SendMessageW(g_state.window_res_combo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(res.label));
  }
  y += row_step;

  g_state.upscale_combo = add_combo_row(L"上采样方式:", kIdUpscaleCombo, g_state.upscale_label,
                                        kUpscaleOptions, std::size(kUpscaleOptions));
  g_state.fps_combo = add_combo_row(L"目标帧率:", kIdFpsCombo, g_state.fps_label, kFpsOptions,
                                    std::size(kFpsOptions));

  y += ScaleDpi(4);
  g_state.vsync_check =
      CreateWindowExW(0, L"BUTTON", L"启用垂直同步 (VSync)",
                      WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_AUTOCHECKBOX, combo_x, y,
                      ScaleDpi(260), ScaleDpi(24), hwnd,
                      reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdVsyncCheck)), nullptr, nullptr);
  set_font(g_state.vsync_check, g_state.ui_font);

  y += ScaleDpi(30);
  g_state.windowed_check =
      CreateWindowExW(0, L"BUTTON", L"窗口化启动 (Windowed)",
                      WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_AUTOCHECKBOX, combo_x, y,
                      ScaleDpi(260), ScaleDpi(24), hwnd,
                      reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdWindowedCheck)), nullptr, nullptr);
  set_font(g_state.windowed_check, g_state.ui_font);

  y += ScaleDpi(44);
  int btn_w = ScaleDpi(140);
  int btn_h = ScaleDpi(34);
  int exit_w = ScaleDpi(96);
  int right_edge = combo_x + combo_w;

  g_state.launch_btn = CreateWindowExW(
      0, L"BUTTON", L"启动游戏", WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_DEFPUSHBUTTON,
      right_edge - btn_w - exit_w - ScaleDpi(12), y, btn_w, btn_h, hwnd,
      reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdLaunchBtn)), nullptr, nullptr);
  set_font(g_state.launch_btn, g_state.ui_font);

  g_state.exit_btn = CreateWindowExW(
      0, L"BUTTON", L"退出", WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON,
      right_edge - exit_w, y, exit_w, btn_h, hwnd,
      reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdExitBtn)), nullptr, nullptr);
  set_font(g_state.exit_btn, g_state.ui_font);

  LoadSavedSettings();
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
  switch (msg) {
    case WM_CREATE:
      g_state.hwnd = hwnd;
      CreateUiControls(hwnd);
      return 0;

    case WM_COMMAND: {
      int id = LOWORD(wparam);
      int code = HIWORD(wparam);
      if (id == kIdLangCombo && code == CBN_SELCHANGE) {
        int lang_idx = ClampIndex(
            static_cast<int>(SendMessageW(g_state.lang_combo, CB_GETCURSEL, 0, 0)),
            static_cast<int>(std::size(kLanguageOptions)));
        ApplyLanguage(lang_idx);
        SaveLanguageSetting(lang_idx);
        return 0;
      }
      if (code == BN_CLICKED) {
        if (id == kIdLaunchBtn) {
          LaunchGame();
          return 0;
        }
        if (id == kIdExitBtn) {
          DestroyWindow(hwnd);
          return 0;
        }
      }
      break;
    }

    case WM_CTLCOLORSTATIC: {
      HDC hdc = reinterpret_cast<HDC>(wparam);
      SetBkMode(hdc, TRANSPARENT);
      return reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_WINDOW));
    }

    case WM_DESTROY:
      if (g_state.ui_font && g_state.ui_font != GetStockObject(DEFAULT_GUI_FONT)) {
        DeleteObject(g_state.ui_font);
      }
      if (g_state.title_font && g_state.title_font != g_state.ui_font &&
          g_state.title_font != GetStockObject(DEFAULT_GUI_FONT)) {
        DeleteObject(g_state.title_font);
      }
      PostQuitMessage(0);
      return 0;
  }
  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

}  // namespace

int WINAPI wWinMain(HINSTANCE hinstance, HINSTANCE, PWSTR, int ncmd_show) {
  SetProcessDPIAware();

  INITCOMMONCONTROLSEX icc = {};
  icc.dwSize = sizeof(icc);
  icc.dwICC = ICC_STANDARD_CLASSES;
  InitCommonControlsEx(&icc);

  HDC screen_dc = GetDC(nullptr);
  if (screen_dc) {
    g_state.dpi = static_cast<UINT>(GetDeviceCaps(screen_dc, LOGPIXELSX));
    ReleaseDC(nullptr, screen_dc);
  }

  WNDCLASSEXW wc = {};
  wc.cbSize = sizeof(wc);
  wc.lpfnWndProc = WindowProc;
  wc.hInstance = hinstance;
  wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
  wc.hIcon = LoadIconW(nullptr, IDI_APPLICATION);
  wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
  wc.lpszClassName = kWindowClassName;

  if (!RegisterClassExW(&wc)) {
    return 1;
  }

  DWORD style = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
  RECT rect = {0, 0, ScaleDpi(480), ScaleDpi(420)};
  AdjustWindowRectEx(&rect, style, FALSE, 0);
  int win_w = rect.right - rect.left;
  int win_h = rect.bottom - rect.top;

  int screen_w = GetSystemMetrics(SM_CXSCREEN);
  int screen_h = GetSystemMetrics(SM_CYSCREEN);
  int pos_x = (screen_w - win_w) / 2;
  int pos_y = (screen_h - win_h) / 2;

  HWND hwnd = CreateWindowExW(0, kWindowClassName,
                              L"首都高赛车X - 启动配置 (Shutokou Battle X Launcher)", style, pos_x,
                              pos_y, win_w, win_h, nullptr, nullptr, hinstance, nullptr);
  if (!hwnd) {
    return 1;
  }

  ShowWindow(hwnd, ncmd_show);
  UpdateWindow(hwnd);

  MSG msg = {};
  while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
    if (!IsDialogMessageW(hwnd, &msg)) {
      TranslateMessage(&msg);
      DispatchMessageW(&msg);
    }
  }

  return static_cast<int>(msg.wParam);
}
