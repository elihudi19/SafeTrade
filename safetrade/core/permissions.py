from rest_framework.permissions import BasePermission


class IsRole(BasePermission):
    """Base class - tumia kwa kuunda permission ya role maalum."""
    role = None

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == self.role
        )


class IsSuperAdmin(IsRole):
    role = "super_admin"


class IsOwner(IsRole):
    role = "owner"


class IsStorekeeper(IsRole):
    role = "storekeeper"


class IsCashier(IsRole):
    role = "cashier"


class IsCustomer(IsRole):
    role = "customer"


class IsOwnerOfBusiness(BasePermission):
    """Object-level: mtumiaji lazima awe Owner wa Business husika."""

    def has_object_permission(self, request, view, obj):
        business = getattr(obj, "business", None) or getattr(obj, "store", None)
        if business is not None and hasattr(business, "business"):
            business = business.business  # obj.store.business
        return bool(
            request.user.role == "owner"
            and business is not None
            and business.owner_id == request.user.id
        )


class IsStaffOfStore(BasePermission):
    """Cashier/Storekeeper wanaruhusiwa tu kwenye duka walilopangiwa."""

    def has_object_permission(self, request, view, obj):
        store = getattr(obj, "store", None)
        return bool(store is not None and store_id_matches(request.user, store))


def store_id_matches(user, store):
    return user.store_id == store.id
