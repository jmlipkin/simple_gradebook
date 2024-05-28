// /////////////////////////////////////////////////////////
//
// File:   clerdle/color.cpp
// Author: William Moon / Michael Foster
// Date:   2022.04.29
//
// This file contains utilities for displaying formatted
// data onto the console.
//
// /////////////////////////////////////////////////////////
#include "color.h"
//--------------//

#include <vector>
#include <string>
#include <iostream>
#include <iomanip>
#include <sstream>

const std::vector<Color> Color::colormap{
    {"black", Color::black, 30, 40},
    {"red", Color::red, 31, 41},
    {"green", Color::green, 32, 42},
    {"yellow", Color::yellow, 33, 43},
    {"blue", Color::blue, 34, 44},
    {"purple", Color::purple, 35, 45},
    {"cyan", Color::cyan, 36, 46},
    {"white", Color::white, 37, 47}};

const std::string Color::escape{"\033["};

Color::Color(const std::string &name_str, name color_name, int fg_code, int bg_code) : m_name_str{name_str},
                                                                                       m_name{color_name},
                                                                                       m_fg{fg_code},
                                                                                       m_bg{bg_code}
{
}

const Color &Color::getByName(name color_name)
{
  const Color &cc = colormap.front();
  for (const auto &c : colormap)
  {
    if (c.getName() == color_name)
    {
      return c;
    }
  }
  return cc;
}

// Sets foreground text color until Color::reset() is called.
std::string Color::setFg(name fg)
{
  std::stringstream s;
  s << escape << getByName(fg).getFgCode() << "m";
  return s.str();
}

// Sets background text color until Color::reset() is called.
std::string Color::setBg(name bg)
{
  std::stringstream s;
  s << escape << getByName(bg).getBgCode() << "m";
  return s.str();
}

// Sets text color according to
// (<foreground color>, <background color>)
// until Color::reset() is called.
std::string Color::setColor(name fg, name bg)
{
  std::stringstream s;
  s << escape << getByName(bg).getBgCode()
    << ";" << getByName(fg).getFgCode()
    << "m";
  return s.str();
}

// Resets foreground and background colors.
std::string Color::reset()
{
  return escape + "0m";
}

void Color::test()
{
  std::cout << "        ";
  for (const auto &c : colormap)
  {
    std::cout << setBg(c.getName()) << " " << std::setw(7) << std::left << c.getNameStr();
  }
  std::cout << reset() << std::endl;
  for (const auto &fg : colormap)
  {
    std::cout << setFg(fg.getName()) << std::setw(8) << fg.getNameStr();

    for (const auto &bg : colormap)
    {
      std::cout << setColor(fg.getName(), bg.getName())
                << " " << fg.getNameStr().substr(0, 2)
                << "|" << bg.getNameStr().substr(0, 2) << "  ";
    }
    std::cout << reset() << std::endl;
  }
  std::cout << reset();
}
