#pragma once
#include <string>
#include <vector>
#include <mutex>
#include <chrono>
#include <sstream>
#include <iomanip>

enum class LogLevel {
    Info,
    Success,
    Warning,
    Error,
    Hook
};

struct LogEntry {
    std::string timestamp;
    LogLevel level;
    std::string message;
};

class Logger {
public:
    static Logger& Instance() {
        static Logger instance;
        return instance;
    }

    void Log(LogLevel level, const std::string& msg) {
        std::lock_guard<std::mutex> lock(m_mutex);

        auto now = std::chrono::system_clock::now();
        auto in_time_t = std::chrono::system_clock::to_time_t(now);
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;

        std::stringstream ss;
        ss << std::put_time(std::localtime(&in_time_t), "%H:%M:%S")
           << '.' << std::setfill('0') << std::setw(3) << ms.count();

        if (m_entries.size() > 500) {
            m_entries.erase(m_entries.begin());
        }
        m_entries.push_back({ ss.str(), level, msg });
    }

    void Info(const std::string& msg)    { Log(LogLevel::Info, msg); }
    void Success(const std::string& msg) { Log(LogLevel::Success, msg); }
    void Warn(const std::string& msg)    { Log(LogLevel::Warning, msg); }
    void Error(const std::string& msg)   { Log(LogLevel::Error, msg); }
    void Hook(const std::string& msg)    { Log(LogLevel::Hook, msg); }

    void Clear() {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_entries.clear();
    }

    std::vector<LogEntry> GetEntries() {
        std::lock_guard<std::mutex> lock(m_mutex);
        return m_entries;
    }

    size_t GetCount() {
        std::lock_guard<std::mutex> lock(m_mutex);
        return m_entries.size();
    }

private:
    Logger() = default;
    std::mutex m_mutex;
    std::vector<LogEntry> m_entries;
};

#define LOG_INFO(...)    Logger::Instance().Info(__VA_ARGS__)
#define LOG_SUCCESS(...) Logger::Instance().Success(__VA_ARGS__)
#define LOG_WARN(...)    Logger::Instance().Warn(__VA_ARGS__)
#define LOG_ERROR(...)   Logger::Instance().Error(__VA_ARGS__)
#define LOG_HOOK(...)    Logger::Instance().Hook(__VA_ARGS__)
