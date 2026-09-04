class Siconos < Formula
  desc "Model and simulate nonsmooth dynamical systems"
  homepage "https://nonsmooth.gricad-pages.univ-grenoble-alpes.fr/siconos/"
  url "https://github.com/siconos/siconos/archive/refs/tags/4.5.0.tar.gz"
  sha256 "9519d5a73511c557e9e955f0b50b21ba9649d559c5219bf767ee55c3083258bc"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "gcc"
  depends_on "gmp"
  depends_on "openblas"

  def install
    # Boost 1.92 rejects the obsolete explicit template argument.
    inreplace "externals/boost_contribs/expm.hpp", "std::abs<real_value_type>(H(i,j))", "std::abs(H(i,j))"

    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DSICONOS_CUSTOM_INSTALL=#{prefix}
      -DISOLATED_INSTALL=ON
      -DWITH_PYTHON_WRAPPER=OFF
      -DWITH_TESTING=OFF
      -DWITH_DOCUMENTATION=OFF
      -DWITH_BULLET=OFF
      -DWITH_SYSTEM_SUITESPARSE=OFF
      -DBLA_VENDOR=OpenBLAS
      -DBLAS_ROOT=#{formula_opt_prefix("openblas")}
      -DLAPACK_ROOT=#{formula_opt_prefix("openblas")}
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    inreplace lib/"cmake/siconos-#{version}/siconos-config.cmake" do |s|
      s.gsub!(/^set\(CMAKE_(?:CXX|C)_COMPILER .*\)\n/, "")
    end
  end

  test do
    (testpath/"test.c").write <<~C
      #include <SolverOptions.h>
      #include <lcp_cst.h>

      int main(void) {
        SolverOptions *options = solver_options_create(SICONOS_LCP_LEMKE);
        int failed = !options || options->solverId != SICONOS_LCP_LEMKE;
        solver_options_delete(options);
        return failed;
      }
    C

    system ENV.cc, "test.c", "-I#{include}/siconos", "-I#{include}/siconos/numerics",
                   "-L#{lib}", "-lsiconos_numerics", "-o", "test"
    system "./test"
  end
end
