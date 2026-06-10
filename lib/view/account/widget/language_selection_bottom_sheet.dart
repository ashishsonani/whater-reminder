import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:water_intake/view/account/controller/account_controller.dart';

class LanguageSelectionBottomSheet extends StatelessWidget {
  const LanguageSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountController>();
    controller.clearSearch();

    return Container(
      height: 600.h,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24.r), topRight: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 8.h),
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(color: AppColors.cardEdge, borderRadius: BorderRadius.circular(2.r)),
          ),
          SizedBox(height: 16.h),
          // Top Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.arrow_back, color: AppColors.ink, size: 22.sp),
                ),
                Expanded(
                  child: Text(
                    AppString.selectLanguage.tr,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.latoBoldBlack16.copyWith(
                      fontSize: 18.sp,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 22.sp),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // Search Box
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.cardEdge, width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.inkFaint, size: 20.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: controller.filterLanguages,
                      style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: AppString.search.tr,
                        hintStyle: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: AppColors.inkFaint),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (controller.searchQuery.value.isNotEmpty) {
                      return GestureDetector(
                        onTap: controller.clearSearch,
                        child: Icon(Icons.close, color: AppColors.inkFaint, size: 18.sp),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          // Languages Card Container
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Obx(() {
                    final list = controller.filteredLanguages;

                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48.sp, color: AppColors.inkFaint),
                            SizedBox(height: 16.h),
                            Text(
                              AppString.noLanguageFound.tr,
                              style: AppTextStyle.latoRegularBlack14.copyWith(
                                color: AppColors.inkSoft,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const Divider(color: AppColors.cardEdge, height: 1, thickness: 1),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return _buildLanguageRow(controller, item);
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildLanguageRow(AccountController controller, LanguageItemData item) {
    return Obx(() {
      bool isSelected = controller.selectedLanguage.value == item.code;
      return InkWell(
        onTap: () {
          controller.changeLanguage(item.code);
          Get.back();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          color: AppColors.card,
          child: Row(
            children: [
              Text(item.flag, style: TextStyle(fontSize: 20.sp)),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  item.displayName,
                  style: AppTextStyle.latoRegularBlack14.copyWith(
                    fontSize: 15.sp,
                    color: AppColors.inkSoft,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_outline, color: AppColors.teal, size: 22.sp) else SizedBox(width: 22.sp),
            ],
          ),
        ),
      );
    });
  }
}
