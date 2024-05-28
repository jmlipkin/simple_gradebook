// ////////////////////////////////////////////////////////
// Author: Jared Lipkin
//   Date: 05/23/2024
//
// TODO: Add file description
//
// ////////////////////////////////////////////////////////

#ifndef COURSE_H
#define COURSE_H

#include "student.h"
#include "gradeditem.h"

#include <vector>

class Course {
    private:
        std::vector<Student *> m_students;
        std::vector<GradedItem *> m_items;

    public:
};

#endif