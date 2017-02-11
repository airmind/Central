package org.airmind.view.adapter;

import android.support.v4.view.PagerAdapter;
import android.view.View;
import android.view.ViewGroup;

import java.util.List;

/**
 * Created by KiBa on 2017/1/5.
 */

public class FrameTypePagerAdapter extends PagerAdapter {

    private List<View> itemList;

    public FrameTypePagerAdapter(List<View> itemList) {
        this.itemList = itemList;
    }

    @Override
    public int getCount() {
        return itemList.size();
    }

    @Override
    public boolean isViewFromObject(View view, Object object) {
        return view == object;
    }

    @Override
    public Object instantiateItem(ViewGroup container, int position) {
        container.addView(itemList.get(position));
        return itemList.get(position);
    }

    @Override
    public void destroyItem(ViewGroup container, int position, Object object) {
        container.removeView(itemList.get(position));
    }
}
