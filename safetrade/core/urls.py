from django.urls import path, include
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("businesses", views.BusinessViewSet, basename="business")
router.register("stores", views.StoreViewSet, basename="store")
router.register("staff", views.StaffViewSet, basename="staff")
router.register("products", views.ProductViewSet, basename="product")
router.register("shelf-stock", views.ShelfStockViewSet, basename="shelf-stock")
router.register("stock-transfers", views.StockTransferViewSet, basename="stock-transfer")
router.register("stock-intakes", views.StockIntakeViewSet, basename="stock-intake")
router.register("expenses", views.ExpenseViewSet, basename="expense")
router.register("discrepancies", views.DiscrepancyFlagViewSet, basename="discrepancy")
router.register("shifts", views.ShiftViewSet, basename="shift")
router.register("receipts", views.ReceiptViewSet, basename="receipt")
router.register("marketplace-listings", views.MarketplaceListingViewSet, basename="listing")
router.register("delivery-options", views.DeliveryOptionViewSet, basename="delivery-option")
router.register("carts", views.CartViewSet, basename="cart")
router.register("orders", views.OrderViewSet, basename="order")
router.register("predictive-alerts", views.PredictiveAlertViewSet, basename="predictive-alert")

urlpatterns = [
    path("", include(router.urls)),
    path("auth/register-owner/", views.OwnerRegistrationView.as_view(), name="register-owner"),
    path("auth/verify-otp/", views.VerifyOTPView.as_view(), name="verify-otp"),
    path("auth/resend-otp/", views.ResendOTPView.as_view(), name="resend-otp"),
    path("auth/me/", views.MeView.as_view(), name="me"),
    path("sync/receipts/", views.OfflineReceiptSyncView.as_view(), name="sync-receipts"),
    path("dashboard/store-overview/", views.OwnerDashboardView.as_view(), name="owner-dashboard"),
    path("reports/profit-loss/", views.ProfitLossReportView.as_view(), name="profit-loss-report"),
    path("audit-logs/", views.AuditLogListView.as_view(), name="audit-logs"),
]
