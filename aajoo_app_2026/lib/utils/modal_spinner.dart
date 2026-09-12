import 'package:get/get.dart';

/// Close a blocking spinner, even when a snackbar is sitting on top of it.
///
/// `Get.back()` cannot be trusted to do this. GetX 4.6.6 begins it with:
///
/// ```dart
/// if (isSnackbarOpen && !closeOverlays) {
///   closeCurrentSnackbar();
///   return;                       // <- the dialog is still there
/// }
/// ```
///
/// A snackbar is a route like any other, so one `Get.back()` closes the TOAST
/// and returns, and the `barrierDismissible: false` spinner underneath it
/// stays for the rest of the session with nothing able to dismiss it.
///
/// That is not a theoretical ordering: the fetch behind these spinners shows an
/// error toast when it fails, so the snackbar is open *exactly* when the
/// spinner most needs closing. It is how listing 29303 became impossible to
/// open from the negotiated-deal banner on 2026-09-12 — the listing failed to
/// parse, the controller toasted, and the close that followed went to the
/// toast.
///
/// `closeOverlays: true` is not the answer either: it pops until no dialog or
/// bottom sheet is left and then pops again, which takes the page with it.
///
/// Clear the toasts first, then close the dialog: with no snackbar open,
/// `Get.back()` does what it is being asked to do.
void closeModalSpinner() {
  if (Get.isSnackbarOpen) Get.closeAllSnackbars();
  if (Get.isDialogOpen ?? false) Get.back();
}
