// host/ocalls_host.cpp
#include <cstdio>
#include <mutex>

namespace { std::mutex g_mu; }

// Must match the EDL declaration exactly
extern "C" void ocall_helloworld()
{
  std::lock_guard<std::mutex> lk(g_mu);
  std::fputs("[HOST] hello from ocall_helloworld()\n", stderr);
  std::fflush(stderr);
}
